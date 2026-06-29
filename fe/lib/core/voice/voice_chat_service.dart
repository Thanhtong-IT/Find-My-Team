import 'dart:async';
import 'package:flutter/foundation.dart';
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
  final Map<String, RTCPeerConnection> _peerConnections = {};
  
  String? _currentTeamId;
  String? _myUserId;
  bool _isMuted = false;
  bool _isInCall = false;

  // Controllers for streams
  final _isInCallController = StreamController<bool>.broadcast();
  final _isMutedController = StreamController<bool>.broadcast();
  final _activeSpeakersController = StreamController<Set<String>>.broadcast();

  Stream<bool> get isInCallStream => _isInCallController.stream;
  Stream<bool> get isMutedStream => _isMutedController.stream;
  Stream<Set<String>> get activeSpeakersStream => _activeSpeakersController.stream;

  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;

  final Set<String> _activeSpeakers = {};

  final Map<String, List<RTCIceCandidate>> _pendingIceCandidates = {};

  // ICE Servers configuration
  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };

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
  }

  Future<bool> joinVoiceRoom(String teamId, String myUserId) async {
    if (_isInCall) {
      if (_currentTeamId == teamId) return true;
      await leaveVoiceRoom();
    }

    debugPrint('[VoiceChat] Joining voice room: teamId=$teamId, myUserId=$myUserId');
    
    // Request Microphone permission
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      debugPrint('[VoiceChat] Microphone permission denied');
      return false;
    }

    _currentTeamId = teamId;
    _myUserId = myUserId;

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
      _isInCallController.add(true);

      // Notify others via WebSocket that we have joined the voice room
      _wsClient?.sendVoiceSignal('VOICE_JOIN', {
        'teamId': teamId,
        'userId': myUserId,
      });

      debugPrint('[VoiceChat] Local stream obtained and VOICE_JOIN sent');
      return true;
    } catch (e) {
      debugPrint('[VoiceChat] Error joining voice room: $e');
      await leaveVoiceRoom();
      return false;
    }
  }

  Future<void> leaveVoiceRoom() async {
    if (!_isInCall) return;

    debugPrint('[VoiceChat] Leaving voice room: teamId=$_currentTeamId');

    // Notify others via WebSocket
    if (_currentTeamId != null && _myUserId != null) {
      _wsClient?.sendVoiceSignal('VOICE_LEAVE', {
        'teamId': _currentTeamId,
        'userId': _myUserId,
      });
    }

    // Clean up local stream
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        track.stop();
      });
      await _localStream!.dispose();
      _localStream = null;
    }

    // Clean up peer connections
    for (var pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    _pendingIceCandidates.clear();

    _currentTeamId = null;
    _myUserId = null;
    _isInCall = false;
    _isInCallController.add(false);
    _activeSpeakers.clear();
    _activeSpeakersController.add({});
  }

  void toggleMute(bool muted) {
    _isMuted = muted;
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = !muted;
      });
    }
    _isMutedController.add(muted);
    debugPrint('[VoiceChat] Mute state changed: isMuted=$_isMuted');
  }

  void _handleVoiceSignal(WsIncomingEvent event) async {
    if (!_isInCall) return;

    final data = event.data;
    final teamId = data['teamId']?.toString();
    if (teamId != _currentTeamId) return;

    final senderId = data['userId']?.toString() ?? data['senderId']?.toString();
    if (senderId == null || senderId == _myUserId) return;

    debugPrint('[VoiceChat] Received voice signal: op=${event.type}, sender=$senderId');

    switch (event.type) {
      case WsEventType.voiceJoin:
        // A new member has joined. We (as the existing member) will initiate the connection.
        await _initiateCall(senderId);
        break;

      case WsEventType.voiceLeave:
        // A member has left. Clean up their connection.
        await _closePeerConnection(senderId);
        break;

      case WsEventType.voiceOffer:
        // We received an offer from senderId. We should answer it.
        final sdp = data['sdp']?.toString();
        if (sdp != null) {
          await _handleOffer(senderId, sdp);
        }
        break;

      case WsEventType.voiceAnswer:
        // We received an answer from senderId.
        final sdp = data['sdp']?.toString();
        if (sdp != null) {
          await _handleAnswer(senderId, sdp);
        }
        break;

      case WsEventType.voiceIceCandidate:
        // We received an ICE candidate.
        final candidateMap = data['candidate'];
        if (candidateMap != null) {
          final candidate = RTCIceCandidate(
            candidateMap['candidate'],
            candidateMap['sdpMid'],
            candidateMap['sdpMLineIndex'],
          );
          await _handleIceCandidate(senderId, candidate);
        }
        break;

      default:
        break;
    }
  }

  Future<void> _initiateCall(String peerId) async {
    debugPrint('[VoiceChat] Initiating call to peer: $peerId');
    if (_peerConnections.containsKey(peerId)) {
      await _closePeerConnection(peerId);
    }

    final pc = await _createPeerConnection(peerId);
    _peerConnections[peerId] = pc;

    // Create SDP Offer
    try {
      final offer = await pc.createOffer(_sdpConstraints);
      await pc.setLocalDescription(offer);

      _wsClient?.sendVoiceSignal('VOICE_OFFER', {
        'teamId': _currentTeamId,
        'userId': _myUserId,
        'targetId': peerId,
        'sdp': offer.sdp,
      });
      debugPrint('[VoiceChat] Sent VOICE_OFFER to peer: $peerId');
    } catch (e) {
      debugPrint('[VoiceChat] Error creating offer to peer $peerId: $e');
    }
  }

  Future<void> _handleOffer(String peerId, String sdp) async {
    debugPrint('[VoiceChat] Handling offer from peer: $peerId');
    if (_peerConnections.containsKey(peerId)) {
      await _closePeerConnection(peerId);
    }

    final pc = await _createPeerConnection(peerId);
    _peerConnections[peerId] = pc;

    try {
      final description = RTCSessionDescription(sdp, 'offer');
      await pc.setRemoteDescription(description);

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
      debugPrint('[VoiceChat] Sent VOICE_ANSWER to peer: $peerId');
    } catch (e) {
      debugPrint('[VoiceChat] Error handling offer from peer $peerId: $e');
    }
  }

  Future<void> _handleAnswer(String peerId, String sdp) async {
    debugPrint('[VoiceChat] Handling answer from peer: $peerId');
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    try {
      final description = RTCSessionDescription(sdp, 'answer');
      await pc.setRemoteDescription(description);
      debugPrint('[VoiceChat] Remote description set for peer: $peerId');
    } catch (e) {
      debugPrint('[VoiceChat] Error setting remote description for peer $peerId: $e');
    }
  }

  Future<void> _handleIceCandidate(String peerId, RTCIceCandidate candidate) async {
    final pc = _peerConnections[peerId];
    if (pc != null && pc.remoteDescription != null) {
      await pc.addCandidate(candidate);
      debugPrint('[VoiceChat] Added ICE candidate directly for peer: $peerId');
    } else {
      // Offer description not set yet, store it in pending candidates list
      _pendingIceCandidates.putIfAbsent(peerId, () => []).add(candidate);
      debugPrint('[VoiceChat] Stored pending ICE candidate for peer: $peerId');
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    final pc = await createPeerConnection(_rtcConfig, _sdpConstraints);

    // Add local stream tracks to peer connection
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    pc.onIceCandidate = (candidate) {
      debugPrint('[VoiceChat] Local ICE candidate gathered for peer: $peerId');
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
      debugPrint('[VoiceChat] Remote track received from peer: $peerId');
      if (event.streams.isNotEmpty) {
        _onRemoteStreamAdded(peerId, event.streams[0]);
      }
    };

    pc.onConnectionState = (state) {
      debugPrint('[VoiceChat] Peer connection state change: $peerId -> $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _activeSpeakers.add(peerId);
        _activeSpeakersController.add(Set.from(_activeSpeakers));
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _activeSpeakers.remove(peerId);
        _activeSpeakersController.add(Set.from(_activeSpeakers));
      }
    };

    return pc;
  }

  void _onRemoteStreamAdded(String peerId, MediaStream stream) {
    debugPrint('[VoiceChat] Remote audio stream active from peer: $peerId');
    // flutter_webrtc will automatically play audio-only tracks when received.
    // However, to configure audio route or sound levels, we can interact with stream here if needed.
    stream.getAudioTracks().forEach((track) {
      track.enabled = true;
    });
  }

  Future<void> _closePeerConnection(String peerId) async {
    final pc = _peerConnections.remove(peerId);
    if (pc != null) {
      await pc.close();
      debugPrint('[VoiceChat] Closed peer connection for: $peerId');
    }
    _pendingIceCandidates.remove(peerId);
    _activeSpeakers.remove(peerId);
    _activeSpeakersController.add(Set.from(_activeSpeakers));
  }

  void dispose() {
    _wsSubscription?.cancel();
    leaveVoiceRoom();
    _isInCallController.close();
    _isMutedController.close();
    _activeSpeakersController.close();
  }
}
