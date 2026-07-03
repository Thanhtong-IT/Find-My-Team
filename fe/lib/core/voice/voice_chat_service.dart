import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/team/services/team_api_service.dart';
import '../websocket/websocket_client.dart';

class VoiceChatService {
  VoiceChatService._();
  static final VoiceChatService instance = VoiceChatService._();

  static const int _volumeIndicationIntervalMs = 250;
  static const int _speakerVolumeThreshold = 10;
  static const int _maxAgoraUid = 0x7fffffff;

  final TeamApiService _teamApiService = TeamApiService();
  final _isInCallController = StreamController<bool>.broadcast();
  final _isMutedController = StreamController<bool>.broadcast();
  final _activeSpeakersController = StreamController<Set<String>>.broadcast();

  Stream<bool> get isInCallStream => _isInCallController.stream;
  Stream<bool> get isMutedStream => _isMutedController.stream;
  Stream<Set<String>> get activeSpeakersStream => _activeSpeakersController.stream;

  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isJoining => _isJoining;

  RtcEngine? _engine;
  String? _currentAppId;
  String? _currentTeamId;
  String? _myUserId;
  int? _localAgoraUid;
  bool _isMuted = true;
  bool _isInCall = false;
  bool _isJoining = false;

  final Set<String> _activeSpeakers = {};
  final Map<int, String> _agoraUidToUserId = {};

  static final List<int> _crcTable = List<int>.generate(256, (index) {
    var c = index;
    for (var i = 0; i < 8; i++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  });

  void init(WebSocketClient _) {}

  void syncTeamMembers(List<String> userIds) {
    final sortedUserIds = userIds.toSet().toList()..sort();
    final nextMap = <int, String>{};
    final usedUids = <int>{};

    for (final userId in sortedUserIds) {
      var candidate = _baseAgoraUid(userId);
      while (candidate == 0 || usedUids.contains(candidate)) {
        candidate = candidate >= _maxAgoraUid ? 1 : candidate + 1;
      }
      usedUids.add(candidate);
      nextMap[candidate] = userId;
    }

    _agoraUidToUserId
      ..clear()
      ..addAll(nextMap);

    final validUserIds = nextMap.values.toSet();
    final nextSpeakers = _activeSpeakers.where(validUserIds.contains).toSet();
    _publishActiveSpeakers(nextSpeakers);
  }

  Future<bool> joinVoiceRoom(String teamId, String myUserId) async {
    if (_isInCall && _currentTeamId == teamId) {
      return true;
    }
    if (_isJoining && _currentTeamId == teamId) {
      return false;
    }
    if (_isInCall || _isJoining) {
      await leaveVoiceRoom();
    }

    _isJoining = true;
    _currentTeamId = teamId;
    _myUserId = myUserId;

    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      _isJoining = false;
      _currentTeamId = null;
      _myUserId = null;
      debugPrint('[VoiceChat] Microphone permission denied');
      return false;
    }

    try {
      final voiceToken = await _teamApiService.getVoiceToken(teamId);
      final responseAppId = (voiceToken['appId']?.toString() ?? '').trim();
      final envAppId = (dotenv.env['AGORA_APP_ID'] ?? '').trim();
      final appId = responseAppId.isNotEmpty ? responseAppId : envAppId;
      final channelName = (voiceToken['channelName']?.toString() ?? '').trim();
      final token = (voiceToken['token']?.toString() ?? '').trim();
      final agoraUid = (voiceToken['agoraUid'] as num?)?.toInt();

      if (appId.isEmpty || channelName.isEmpty || token.isEmpty || agoraUid == null) {
        throw StateError('Missing Agora voice token payload');
      }

      _localAgoraUid = agoraUid;
      _syncMembersFromTokenResponse(voiceToken, myUserId);
      await _ensureEngine(appId);

      debugPrint('[VoiceChat] Joining Agora: appId=$appId channel=$channelName uid=$agoraUid tokenLength=${token.length}');
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: agoraUid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      _isInCall = true;
      _isJoining = false;
      _isInCallController.add(true);
      unawaited(_applyLocalAudioState());
      debugPrint('[VoiceChat] Joined Agora voice room: teamId=$teamId uid=$agoraUid');
      return true;
    } catch (e) {
      debugPrint('[VoiceChat] Error joining Agora voice room: $e');
      _isJoining = false;
      await leaveVoiceRoom();
      return false;
    }
  }

  Future<void> leaveVoiceRoom() async {
    final engine = _engine;
    final hadActiveSession = _isInCall || _isJoining || engine != null;
    if (!hadActiveSession) return;

    debugPrint('[VoiceChat] Leaving voice room: teamId=$_currentTeamId');

    _isJoining = false;

    if (engine != null) {
      try {
        await engine.leaveChannel();
      } catch (e) {
        debugPrint('[VoiceChat] Error leaving Agora channel: $e');
      }
      await _disposeEngine();
    }

    _currentTeamId = null;
    _myUserId = null;
    _currentAppId = null;
    _localAgoraUid = null;
    _isInCall = false;
    _isInCallController.add(false);
    _agoraUidToUserId.clear();
    _publishActiveSpeakers({});
  }

  void toggleMute(bool muted) {
    _isMuted = muted;
    _isMutedController.add(muted);

    if (_engine != null) {
      unawaited(_applyLocalAudioState());
    }

    if (muted && _myUserId != null) {
      final nextSpeakers = Set<String>.from(_activeSpeakers)..remove(_myUserId);
      _publishActiveSpeakers(nextSpeakers);
    }
  }

  Future<void> _applyLocalAudioState() async {
    final engine = _engine;
    if (engine == null) return;

    try {
      await engine.setEnableSpeakerphone(true);
    } catch (e) {
      debugPrint('[VoiceChat] Failed to enable speakerphone: $e');
    }

    try {
      await engine.muteLocalAudioStream(_isMuted);
      debugPrint('[VoiceChat] Applied local audio state: muted=$_isMuted');
    } catch (e) {
      debugPrint('[VoiceChat] Failed to apply mute state: muted=$_isMuted error=$e');
    }
  }

  Future<void> _ensureEngine(String appId) async {
    if (_engine != null && _currentAppId == appId) {
      return;
    }

    await _disposeEngine();

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(appId: appId),
    );

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onError: (err, msg) {
          debugPrint('[VoiceChat] Agora error: err=$err msg=$msg');
        },
        onJoinChannelSuccess: (connection, uid) {
          debugPrint('[VoiceChat] Agora join success: channel=${connection.channelId} uid=$uid');
        },
        onUserJoined: (connection, uid, elapsed) {
          final userId = _agoraUidToUserId[uid];
          debugPrint('[VoiceChat] Remote user joined Agora channel: uid=$uid userId=$userId elapsed=$elapsed');
        },
        onUserOffline: (connection, remoteUid, reason) {
          final userId = _agoraUidToUserId[remoteUid];
          debugPrint('[VoiceChat] Remote user offline: uid=$remoteUid userId=$userId reason=$reason');
          if (userId == null) return;
          final nextSpeakers = Set<String>.from(_activeSpeakers)..remove(userId);
          _publishActiveSpeakers(nextSpeakers);
        },
        onLocalAudioStateChanged: (connection, state, reason) {
          debugPrint('[VoiceChat] Local audio state: channel=${connection.channelId} state=$state reason=$reason muted=$_isMuted');
        },
        onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
          final userId = _agoraUidToUserId[remoteUid];
          debugPrint('[VoiceChat] Remote audio state: channel=${connection.channelId} uid=$remoteUid userId=$userId state=$state reason=$reason elapsed=$elapsed');
        },
        onAudioPublishStateChanged: (channel, oldState, newState, elapsed) {
          debugPrint('[VoiceChat] Audio publish state: channel=$channel old=$oldState new=$newState elapsed=$elapsed muted=$_isMuted');
        },
        onAudioSubscribeStateChanged: (channel, uid, oldState, newState, elapsed) {
          final userId = _agoraUidToUserId[uid];
          debugPrint('[VoiceChat] Audio subscribe state: channel=$channel uid=$uid userId=$userId old=$oldState new=$newState elapsed=$elapsed');
        },
        onUserMuteAudio: (connection, remoteUid, muted) {
          final userId = _agoraUidToUserId[remoteUid];
          debugPrint('[VoiceChat] Remote user mute changed: uid=$remoteUid userId=$userId muted=$muted');
        },
        onRemoteAudioStats: (connection, stats) {
          debugPrint('[VoiceChat] Remote audio stats: channel=${connection.channelId} stats=${stats.toJson()}');
        },
        onAudioRoutingChanged: (routing) {
          debugPrint('[VoiceChat] Audio routing changed: routing=$routing');
        },
        onPermissionError: (permissionType) {
          debugPrint('[VoiceChat] Agora permission error: type=$permissionType');
        },
        onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
          final nextSpeakers = <String>{};
          for (final speaker in speakers) {
            final volume = speaker.volume ?? 0;
            final vad = speaker.vad ?? 0;

            if (speaker.uid == 0) {
              if (_myUserId != null && !_isMuted && (vad == 1 || volume > _speakerVolumeThreshold)) {
                nextSpeakers.add(_myUserId!);
              }
              continue;
            }

            if (volume <= _speakerVolumeThreshold) {
              continue;
            }

            final userId = _agoraUidToUserId[speaker.uid];
            if (userId != null) {
              nextSpeakers.add(userId);
            }
          }
          _publishActiveSpeakers(nextSpeakers);
        },
        onTokenPrivilegeWillExpire: (connection, token) {
          _renewAgoraToken();
        },
        onRequestToken: (connection) {
          _renewAgoraToken();
        },
        onConnectionStateChanged: (connection, state, reason) {
          debugPrint('[VoiceChat] Agora connection state: state=$state reason=$reason');
        },
        onLeaveChannel: (connection, stats) {
          debugPrint('[VoiceChat] Left Agora channel: channel=${connection.channelId} stats=${stats.toJson()}');
        },
      ),
    );

    await engine.enableAudio();
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );
    await engine.enableAudioVolumeIndication(
      interval: _volumeIndicationIntervalMs,
      smooth: 3,
      reportVad: true,
    );

    _engine = engine;
    _currentAppId = appId;
  }

  Future<void> _disposeEngine() async {
    final engine = _engine;
    _engine = null;
    if (engine == null) return;

    try {
      await engine.release();
    } catch (e) {
      debugPrint('[VoiceChat] Error releasing Agora engine: $e');
    }
  }

  Future<void> _renewAgoraToken() async {
    final teamId = _currentTeamId;
    final engine = _engine;
    if (teamId == null || engine == null || !_isInCall) {
      return;
    }

    try {
      final voiceToken = await _teamApiService.getVoiceToken(teamId);
      final token = (voiceToken['token']?.toString() ?? '').trim();
      if (token.isEmpty) {
        return;
      }
      _syncMembersFromTokenResponse(voiceToken, _myUserId);
      await engine.renewToken(token);
      debugPrint('[VoiceChat] Renewed Agora token');
    } catch (e) {
      debugPrint('[VoiceChat] Error renewing Agora token: $e');
    }
  }

  void _syncMembersFromTokenResponse(Map<String, dynamic> payload, String? fallbackUserId) {
    final members = payload['members'];
    if (members is! List) {
      if (_localAgoraUid != null && fallbackUserId != null) {
        _agoraUidToUserId[_localAgoraUid!] = fallbackUserId;
      }
      return;
    }

    _agoraUidToUserId.clear();
    for (final entry in members) {
      if (entry is! Map) continue;
      final userId = entry['userId']?.toString();
      final agoraUid = (entry['agoraUid'] as num?)?.toInt();
      if (userId == null || userId.isEmpty || agoraUid == null) continue;
      _agoraUidToUserId[agoraUid] = userId;
    }

    if (_localAgoraUid != null && fallbackUserId != null) {
      _agoraUidToUserId[_localAgoraUid!] = fallbackUserId;
    }
  }

  void _publishActiveSpeakers(Set<String> nextSpeakers) {
    if (_activeSpeakers.length == nextSpeakers.length && _activeSpeakers.containsAll(nextSpeakers)) {
      return;
    }

    _activeSpeakers
      ..clear()
      ..addAll(nextSpeakers);
    _activeSpeakersController.add(Set.from(_activeSpeakers));
  }

  int _baseAgoraUid(String userId) {
    var crc = 0xffffffff;
    for (final byte in utf8.encode(userId)) {
      crc = _crcTable[(crc ^ byte) & 0xff] ^ (crc >> 8);
    }
    final value = (crc ^ 0xffffffff) & _maxAgoraUid;
    return value == 0 ? 1 : value;
  }

  Future<void> dispose() async {
    await leaveVoiceRoom();
    await _disposeEngine();
    await _isInCallController.close();
    await _isMutedController.close();
    await _activeSpeakersController.close();
  }
}
