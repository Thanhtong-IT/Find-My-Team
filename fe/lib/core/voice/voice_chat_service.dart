import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../websocket/websocket_client.dart';
import '../events/event_bus.dart';

class VoiceChatService {
  VoiceChatService._();
  static final VoiceChatService instance = VoiceChatService._();

  WebSocketClient? _wsClient;
  StreamSubscription? _wsSubscription;

  MediaStream? _localStream;
  final Map<String, MediaStream> _remoteStreams = {};
  final Map<String, RTCPeerConnection> _peerConnections = {};

  String? _currentTeamId;
  String? _myUserId;
  bool _isMuted = true;
  bool _isInCall = false;
  bool _isJoining = false;
  bool _isPollingVoiceActivity = false;

  static const Duration _voiceActivityPollInterval = Duration(milliseconds: 250);
  static const Duration _speakerHoldDuration = Duration(milliseconds: 500);
  static const double _startSpeakingThreshold = 0.06;
  static const double _continueSpeakingThreshold = 0.03;

  // Controllers for streams
  final _isInCallController = StreamController<bool>.broadcast();
  final _isMutedController = StreamController<bool>.broadcast();
  final _activeSpeakersController = StreamController<Set<String>>.broadcast();

  Stream<bool> get isInCallStream => _isInCallController.stream;
  Stream<bool> get isMutedStream => _isMutedController.stream;
  Stream<Set<String>> get activeSpeakersStream => _activeSpeakersController.stream;

  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isJoining => _isJoining;

  final Set<String> _activeSpeakers = {};
  final Set<String> _remoteDescriptionPeers = {};
  final Map<String, DateTime> _lastSpeechDetectedAt = {};
  final Map<String, double> _lastAudioEnergy = {};
  final Map<String, double> _lastSamplesDuration = {};

  final Map<String, List<RTCIceCandidate>> _pendingIceCandidates = {};
  Timer? _voiceActivityTimer;

  // TURN credentials are injected through Flutter's .env file. When they are
  // absent, voice chat still works with STUN on networks that allow direct P2P.
  Map<String, dynamic> get _rtcConfig {
    final turnHost = dotenv.env['TURN_HOST']?.trim() ?? '';
    final turnUsername = dotenv.env['TURN_USERNAME']?.trim() ?? '';
    final turnCredential = dotenv.env['TURN_CREDENTIAL']?.trim() ?? '';
    final turnTlsEnabled =
        (dotenv.env['TURN_TLS_ENABLED'] ?? 'false').toLowerCase() == 'true';

    final iceServers = <Map<String, dynamic>>[
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ];

    if (turnHost.isNotEmpty &&
        turnUsername.isNotEmpty &&
        turnCredential.isNotEmpty) {
      iceServers.add({
        'urls': [
          'turn:$turnHost:3478?transport=udp',
          'turn:$turnHost:3478?transport=tcp',
          if (turnTlsEnabled) 'turns:$turnHost:5349?transport=tcp',
        ],
        'username': turnUsername,
        'credential': turnCredential,
      });
    }

    debugPrint('[VoiceChat] RTC Config ICE servers: $iceServers');
    return {'iceServers': iceServers};
  }

  final Map<String, dynamic> _sdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

  void init(WebSocketClient wsClient) {
    _wsClient = wsClient;
    _wsSubscription?.cancel();
    _wsSubscription = AppEventBus.instance.voiceEventStream.listen(_handleVoiceSignal);
    debugPrint('[Voice] Service initialized');
  }

  Future<bool> joinVoiceRoom(String teamId, String myUserId) async {
    if (_isInCall && _currentTeamId == teamId) {
      debugPrint('[Voice] Already in call for team: $teamId');
      return true;
    }
    if (_isJoining && _currentTeamId == teamId) {
      debugPrint('[Voice] Already joining team: $teamId');
      return false;
    }
    if (_isInCall) {
      debugPrint('[Voice] Leaving current call before joining new one');
      await leaveVoiceRoom();
    }

    debugPrint('[Voice] Joining voice room: teamId=$teamId, myUserId=$myUserId');
    debugPrint('[Voice] Joining voice room: $teamId'); // Will update to true if successful

    _isJoining = true;
    _currentTeamId = teamId;
    _myUserId = myUserId;

    // Request Microphone permission
    debugPrint('[Voice] Requesting microphone permission...');
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      debugPrint('[Voice] Microphone permission denied');
      _isJoining = false;
      _currentTeamId = null;
      _myUserId = null;
      return false;
    }
    debugPrint('[Voice] Microphone permission granted');

    try {
      // Get local audio stream
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = !_isMuted;
      });

      _isInCall = true;
      _isJoining = false;
      _isInCallController.add(true);
      _startVoiceActivityPolling();

      // Notify others via WebSocket that we have joined the voice room
      _wsClient?.sendVoiceSignal('VOICE_JOIN', {
        'teamId': teamId,
        'userId': myUserId,
      });

      debugPrint('[Voice] Joined voice room: $teamId');
      return true;
    } catch (e) {
      debugPrint('[Voice] Joining voice room failed: $teamId - $e');
      _isJoining = false;
      await leaveVoiceRoom();
      return false;
    }
  }

  Future<void> leaveVoiceRoom() async {
    if (!_isInCall) {
      debugPrint('[Voice] Leave called but not in call');
      return;
    }

    debugPrint('[Voice] Leaving voice room: teamId=$_currentTeamId');

    // Notify others via WebSocket
    if (_currentTeamId != null && _myUserId != null) {
      _wsClient?.sendVoiceSignal('VOICE_LEAVE', {
        'teamId': _currentTeamId,
        'userId': _myUserId,
      });
    }

    _stopVoiceActivityPolling();

    // Clean up local stream
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        track.stop();
      });
      await _localStream!.dispose();
      _localStream = null;
    }

    // Clean up remote streams
    for (var entry in _remoteStreams.entries) {
      entry.value.getTracks().forEach((track) => track.stop());
      await entry.value.dispose();
    }
    _remoteStreams.clear();

    // Clean up peer connections
    for (var pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    _pendingIceCandidates.clear();
    _remoteDescriptionPeers.clear();
    _lastSpeechDetectedAt.clear();
    _lastAudioEnergy.clear();
    _lastSamplesDuration.clear();

    _currentTeamId = null;
    _myUserId = null;
    _isInCall = false;
    _isInCallController.add(false);
    _activeSpeakers.clear();
    _activeSpeakersController.add({});

    debugPrint('[Voice] Left voice room');
  }

  void toggleMute(bool muted) {
    _isMuted = muted;
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = !muted;
      });
    }
    if (muted && _myUserId != null) {
      _clearVoiceActivityStateForSource(_myUserId!);
      if (_activeSpeakers.remove(_myUserId)) {
        _activeSpeakersController.add(Set.from(_activeSpeakers));
      }
    }
    _isMutedController.add(muted);
    debugPrint('[Voice] Mute toggled: isMuted=$_isMuted');
  }

  void _handleVoiceSignal(WsIncomingEvent event) async {
    if (!_isInCall) {
      debugPrint('[Voice] Ignoring voice signal - not in call');
      return;
    }

    final data = event.data;
    final teamId = data['teamId']?.toString();
    if (teamId != _currentTeamId) {
      debugPrint('[Voice] Ignoring voice signal - wrong team: $teamId vs $_currentTeamId');
      return;
    }

    final senderId = data['userId']?.toString() ?? data['senderId']?.toString();
    if (senderId == null || senderId == _myUserId) {
      debugPrint('[Voice] Ignoring voice signal - self signal');
      return;
    }

    debugPrint('[Voice] Received: ${event.type} from $senderId');

    switch (event.type) {
      case WsEventType.voiceJoin:
        debugPrint('[Voice] User joined: $senderId - initiating call');
        await _initiateCall(senderId);
        break;

      case WsEventType.voiceLeave:
        debugPrint('[Voice] User left: $senderId - closing peer connection');
        await _closePeerConnection(senderId);
        break;

      case WsEventType.voiceOffer:
        final sdp = data['sdp']?.toString();
        if (sdp != null) {
          debugPrint('[Voice] Received offer from $senderId, SDP: ${sdp.length} chars');
          await _handleOffer(senderId, sdp);
        }
        break;

      case WsEventType.voiceAnswer:
        final sdp = data['sdp']?.toString();
        if (sdp != null) {
          debugPrint('[Voice] Received answer from $senderId, SDP: ${sdp.length} chars');
          await _handleAnswer(senderId, sdp);
        }
        break;

      case WsEventType.voiceIceCandidate:
        final candidateMap = data['candidate'];
        if (candidateMap != null) {
          debugPrint('[Voice] Received ICE candidate from $senderId');
          final candidate = RTCIceCandidate(
            candidateMap['candidate'],
            candidateMap['sdpMid'],
            candidateMap['sdpMLineIndex'],
          );
          await _handleIceCandidate(senderId, candidate);
        }
        break;

      default:
        debugPrint('[Voice] Unknown voice event type: ${event.type}');
        break;
    }
  }

  Future<void> _initiateCall(String peerId) async {
    debugPrint('[Voice] Initiating call to: $peerId');
    if (_peerConnections.containsKey(peerId)) {
      debugPrint('[Voice] Existing peer connection found, closing first');
      await _closePeerConnection(peerId);
    }

    final pc = await _createPeerConnection(peerId);
    _peerConnections[peerId] = pc;

    // Create SDP Offer
    try {
      debugPrint('[Voice] Creating offer...');
      final offer = await pc.createOffer(_sdpConstraints);
      await pc.setLocalDescription(offer);
      debugPrint('[Voice] Offer created, SDP: ${offer.sdp?.length ?? 0} chars');

      _wsClient?.sendVoiceSignal('VOICE_OFFER', {
        'teamId': _currentTeamId,
        'userId': _myUserId,
        'targetId': peerId,
        'sdp': offer.sdp,
      });
      debugPrint('[Voice] Sent VOICE_OFFER to: $peerId');
    } catch (e) {
      debugPrint('[Voice] Error creating offer to $peerId: $e');
    }
  }

  Future<void> _handleOffer(String peerId, String sdp) async {
    debugPrint('[Voice] Handling offer from: $peerId');
    if (_peerConnections.containsKey(peerId)) {
      await _closePeerConnection(peerId);
    }

    final pc = await _createPeerConnection(peerId);
    _peerConnections[peerId] = pc;

    try {
      final description = RTCSessionDescription(sdp, 'offer');
      await pc.setRemoteDescription(description);
      _remoteDescriptionPeers.add(peerId);
      debugPrint('[Voice] Remote description set for: $peerId');

      // Process any ice candidates received before the offer description was set
      if (_pendingIceCandidates.containsKey(peerId)) {
        for (var candidate in _pendingIceCandidates[peerId]!) {
          await pc.addCandidate(candidate);
        }
        _pendingIceCandidates.remove(peerId);
      }

      final answer = await pc.createAnswer(_sdpConstraints);
      await pc.setLocalDescription(answer);

      _wsClient?.sendVoiceSignal('VOICE_ANSWER', {
        'teamId': _currentTeamId,
        'userId': _myUserId,
        'targetId': peerId,
        'sdp': answer.sdp,
      });
      debugPrint('[Voice] Sent VOICE_ANSWER to: $peerId');
    } catch (e) {
      debugPrint('[Voice] Error handling offer from $peerId: $e');
    }
  }

  Future<void> _handleAnswer(String peerId, String sdp) async {
    debugPrint('[Voice] Handling answer from: $peerId');
    final pc = _peerConnections[peerId];
    if (pc == null) {
      debugPrint('[Voice] No peer connection found for: $peerId');
      return;
    }

    try {
      final description = RTCSessionDescription(sdp, 'answer');
      await pc.setRemoteDescription(description);
      if (!_remoteDescriptionPeers.contains(peerId)) {
        _remoteDescriptionPeers.add(peerId);
      }
      debugPrint('[Voice] Peer connected: $peerId - success');
    } catch (e) {
      // Handle race condition where answer arrives but connection already has remote description
      debugPrint('[Voice] Error setting remote description for $peerId: $e');
      // Still add to remoteDescriptionPeers to allow ICE candidates
      if (!_remoteDescriptionPeers.contains(peerId)) {
        _remoteDescriptionPeers.add(peerId);
      }
    }
  }

  Future<void> _handleIceCandidate(String peerId, RTCIceCandidate candidate) async {
    final pc = _peerConnections[peerId];
    if (pc != null && _remoteDescriptionPeers.contains(peerId)) {
      await pc.addCandidate(candidate);
      debugPrint('[Voice] Added ICE candidate for: $peerId');
    } else {
      _pendingIceCandidates.putIfAbsent(peerId, () => []).add(candidate);
      debugPrint('[Voice] Stored pending ICE candidate for: $peerId');
    }
  }

  void _startVoiceActivityPolling() {
    _voiceActivityTimer?.cancel();
    _voiceActivityTimer = Timer.periodic(_voiceActivityPollInterval, (_) {
      _pollVoiceActivity();
    });
    _pollVoiceActivity();
  }

  void _stopVoiceActivityPolling() {
    _voiceActivityTimer?.cancel();
    _voiceActivityTimer = null;
    _isPollingVoiceActivity = false;
  }

  Future<void> _pollVoiceActivity() async {
    if (!_isInCall || _isPollingVoiceActivity) return;

    _isPollingVoiceActivity = true;
    try {
      final now = DateTime.now();
      final nextSpeakers = <String>{};

      if (!_isMuted && _myUserId != null) {
        final localLevel = await _getLocalAudioLevel();
        if (_isSourceSpeaking(_myUserId!, localLevel, now)) {
          nextSpeakers.add(_myUserId!);
        }
      }

      for (final entry in _peerConnections.entries) {
        final remoteLevel = await _getRemoteAudioLevel(entry.value, entry.key);
        if (_isSourceSpeaking(entry.key, remoteLevel, now)) {
          nextSpeakers.add(entry.key);
        }
      }

      if (_activeSpeakers.length != nextSpeakers.length ||
          !_activeSpeakers.containsAll(nextSpeakers)) {
        _activeSpeakers
          ..clear()
          ..addAll(nextSpeakers);
        _activeSpeakersController.add(Set.from(_activeSpeakers));
      }
    } finally {
      _isPollingVoiceActivity = false;
    }
  }

  bool _isSourceSpeaking(String sourceId, double? level, DateTime now) {
    if (level != null) {
      final threshold = _activeSpeakers.contains(sourceId)
          ? _continueSpeakingThreshold
          : _startSpeakingThreshold;
      if (level >= threshold) {
        _lastSpeechDetectedAt[sourceId] = now;
        return true;
      }
    }

    final lastDetectedAt = _lastSpeechDetectedAt[sourceId];
    if (lastDetectedAt == null) {
      return false;
    }

    final stillHolding = now.difference(lastDetectedAt) <= _speakerHoldDuration;
    if (!stillHolding) {
      _lastSpeechDetectedAt.remove(sourceId);
    }
    return stillHolding;
  }

  Future<double?> _getLocalAudioLevel() async {
    for (final pc in _peerConnections.values) {
      final senders = await pc.getSenders();
      for (final sender in senders) {
        final track = sender.track;
        if (track?.kind != 'audio') continue;
        final level = _extractAudioLevel(await sender.getStats(), _myUserId!);
        if (level != null) {
          return level;
        }
      }
    }
    return null;
  }

  Future<double?> _getRemoteAudioLevel(RTCPeerConnection pc, String peerId) async {
    final receivers = await pc.getReceivers();
    for (final receiver in receivers) {
      final track = receiver.track;
      if (track?.kind != 'audio') continue;
      final level = _extractAudioLevel(await receiver.getStats(), peerId);
      if (level != null) {
        return level;
      }
    }
    return null;
  }

  double? _extractAudioLevel(List<StatsReport> reports, String sourceId) {
    for (final report in reports) {
      if (!_isAudioStatsReport(report)) continue;

      final directLevel = _parseDouble(report.values['audioLevel']);
      if (directLevel != null) {
        return directLevel;
      }

      final totalAudioEnergy = _parseDouble(report.values['totalAudioEnergy']);
      final totalSamplesDuration = _parseDouble(report.values['totalSamplesDuration']);
      if (totalAudioEnergy == null || totalSamplesDuration == null) {
        continue;
      }

      final previousEnergy = _lastAudioEnergy[sourceId];
      final previousDuration = _lastSamplesDuration[sourceId];
      _lastAudioEnergy[sourceId] = totalAudioEnergy;
      _lastSamplesDuration[sourceId] = totalSamplesDuration;

      if (previousEnergy == null || previousDuration == null) {
        continue;
      }

      final energyDelta = totalAudioEnergy - previousEnergy;
      final durationDelta = totalSamplesDuration - previousDuration;
      if (energyDelta > 0 && durationDelta > 0) {
        return energyDelta / durationDelta;
      }
    }
    return null;
  }

  bool _isAudioStatsReport(StatsReport report) {
    final type = report.type;
    if (type != 'media-source' &&
        type != 'track' &&
        type != 'outbound-rtp' &&
        type != 'inbound-rtp' &&
        type != 'remote-inbound-rtp') {
      return false;
    }

    final mediaType = report.values['mediaType']?.toString();
    final kind = report.values['kind']?.toString();
    final trackIdentifier = report.values['trackIdentifier']?.toString();
    return mediaType == 'audio' ||
        kind == 'audio' ||
        trackIdentifier?.contains('audio') == true ||
        report.values.containsKey('audioLevel') ||
        report.values.containsKey('totalAudioEnergy');
  }

  double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _clearVoiceActivityStateForSource(String sourceId) {
    _lastSpeechDetectedAt.remove(sourceId);
    _lastAudioEnergy.remove(sourceId);
    _lastSamplesDuration.remove(sourceId);
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    debugPrint('[Voice] Creating peer connection for: $peerId');
    final pc = await createPeerConnection(_rtcConfig, _sdpConstraints);

    // Add local stream tracks to peer connection
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        debugPrint('[Voice] Adding local track: ${track.id}, kind: ${track.kind}');
        pc.addTrack(track, _localStream!);
      });
    }

    pc.onIceCandidate = (candidate) {
      final candidateType = candidate.candidate?.contains(' typ relay') == true
          ? 'relay (TURN)'
          : 'direct';
      debugPrint('[Voice] ICE candidate generated for $peerId: $candidateType');
      _wsClient?.sendVoiceSignal('VOICE_ICE_CANDIDATE', {
        'teamId': _currentTeamId,
        'userId': _myUserId,
        'targetId': peerId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }
      });
    };

    pc.onTrack = (event) {
      debugPrint('[Voice] Remote track received from: $peerId, streams: ${event.streams.length}');
      if (event.streams.isNotEmpty) {
        _onRemoteStreamAdded(peerId, event.streams[0]);
      }
    };

    pc.onConnectionState = (state) {
      debugPrint('[Voice] Peer connection state: $peerId -> $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _activeSpeakers.remove(peerId);
        _lastSpeechDetectedAt.remove(peerId);
        _activeSpeakersController.add(Set.from(_activeSpeakers));
      }
    };

    return pc;
  }

  void _onRemoteStreamAdded(String peerId, MediaStream stream) {
    debugPrint('[Voice] Remote stream added: $peerId, streamId: ${stream.id}');

    // Store the remote stream - this is crucial for audio playback
    _remoteStreams[peerId] = stream;

    // Enable audio tracks
    stream.getAudioTracks().forEach((track) {
      debugPrint('[Voice] Remote audio track: ${track.id}, enabled: ${track.enabled}');
      track.enabled = true;
    });
  }

  Future<void> _closePeerConnection(String peerId) async {
    final pc = _peerConnections.remove(peerId);
    if (pc != null) {
      await pc.close();
      debugPrint('[Voice] Closed peer connection: $peerId');
    }

    // Clean up remote stream for this peer
    final remoteStream = _remoteStreams.remove(peerId);
    if (remoteStream != null) {
      remoteStream.getTracks().forEach((track) => track.stop());
      await remoteStream.dispose();
      debugPrint('[Voice] Disposed remote stream: $peerId');
    }

    _pendingIceCandidates.remove(peerId);
    _remoteDescriptionPeers.remove(peerId);
    _activeSpeakers.remove(peerId);
    _activeSpeakersController.add(Set.from(_activeSpeakers));
  }

  void dispose() {
    debugPrint('[Voice] Disposing voice chat service');
    _wsSubscription?.cancel();
    leaveVoiceRoom();
    _isInCallController.close();
    _isMutedController.close();
    _activeSpeakersController.close();
    debugPrint('[Voice] Service disposed');
  }
}
