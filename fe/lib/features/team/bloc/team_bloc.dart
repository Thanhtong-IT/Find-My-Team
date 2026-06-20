import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/events/event_bus.dart';
import '../../../core/websocket/websocket_client.dart';
import '../models/team_model.dart';
import '../services/team_api_service.dart';
import 'team_event.dart' as ev;
import 'team_state.dart';

class TeamBloc extends Bloc<ev.TeamEvent, TeamState> {
  final TeamApiService _teamApiService;
  final WebSocketClient _wsClient;
  StreamSubscription? _wsSub;
  StreamSubscription? _connSub;
  StreamSubscription? _teamReloadSub;

  TeamBloc({
    required TeamApiService teamApiService,
    WebSocketClient? wsClient,
  })  : _teamApiService = teamApiService,
        _wsClient = wsClient ?? WebSocketClient.instance,
        super(const TeamState()) {
    on<ev.TeamLoadRequested>(_onLoadRequested);
    on<ev.TeamCreateRequested>(_onCreateRequested);
    on<ev.TeamReadyToggled>(_onReadyToggled);
    on<ev.TeamLeaveRequested>(_onLeaveRequested);
    on<ev.TeamDisbandRequested>(_onDisbandRequested);
    on<ev.TeamJoinRequestsLoadRequested>(_onJoinRequestsLoadRequested);
    on<ev.JoinRequestAccepted>(_onAcceptRequest);
    on<ev.JoinRequestRejected>(_onRejectRequest);
    on<ev.TeamOpenLoadRequested>(_onOpenTeamsLoadRequested);
    on<ev.TeamJoinRequestSent>(_onJoinRequestSent);
    on<ev.TeamMemberJoinedEvent>(_onMemberJoined);
    on<ev.TeamMemberLeftEvent>(_onMemberLeft);
    on<ev.TeamMemberReadyEvent>(_onMemberReady);
    on<ev.TeamDisbandedEvent>(_onTeamDisbanded);
    on<ev.JoinRequestCreatedEvent>(_onJoinRequestCreated);

    _listenWebSocket();
    _listenConnection();
    _listenTeamReload();
  }

  void _listenTeamReload() {
    _teamReloadSub = AppEventBus.instance.teamReloadStream.listen((_) {
      add(const ev.TeamLoadRequested());
    });
  }

  void _listenWebSocket() {
    _wsSub = AppEventBus.instance.teamEventStream.listen((event) {
      switch (event.type) {
        case WsEventType.teamMemberJoined:
          add(ev.TeamMemberJoinedEvent(
            userId: event.data['userId']?.toString() ?? '',
            displayName: event.data['displayName'] as String? ?? '',
          ));
          break;
        case WsEventType.teamMemberLeft:
          add(ev.TeamMemberLeftEvent(event.data['userId']?.toString() ?? ''));
          break;
        case WsEventType.teamMemberReady:
          add(ev.TeamMemberReadyEvent(
            userId: event.data['userId']?.toString() ?? '',
            isReady: event.data['isReady'] as bool? ?? false,
          ));
          break;
        case WsEventType.teamDisbanded:
          add(const ev.TeamDisbandedEvent());
          break;
        case WsEventType.joinRequestAccepted:
          add(const ev.TeamLoadRequested());
          break;
        case WsEventType.joinRequestCreated:
          add(ev.JoinRequestCreatedEvent(
            JoinRequestModel(
              id: (event.data['requestId'] ?? event.data['id'])?.toString() ?? '',
              teamId: event.data['teamId']?.toString() ?? '',
              userId: event.data['userId']?.toString() ?? '',
              userDisplayName: event.data['displayName'] as String? ?? '',
              message: event.data['message'] as String?,
              createdAt: DateTime.now(),
            ),
          ));
          break;
        default:
          break;
      }
    });
  }

  void _listenConnection() {
    _connSub = _wsClient.statusStream.listen((status) {
      if (status == WsConnectionStatus.connected && state.currentTeam != null) {
        _wsClient.subscribeRoom(state.currentTeam!.id, 'team');
      }
    });
  }

  Future<void> _onLoadRequested(
    ev.TeamLoadRequested event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.copyWith(status: TeamStatus.loading));
    try {
      final team = await _teamApiService.getMyTeam();
      if (team != null) {
        _wsClient.subscribeRoom(team.id, 'team');
      }
      emit(state.copyWith(status: TeamStatus.loaded, currentTeam: team, clearTeam: team == null));
    } catch (e) {
      debugPrint('[TeamBloc] _onLoadRequested ERROR: $e');
      emit(state.copyWith(status: TeamStatus.error, errorMessage: 'Không thể tải nhóm: $e'));
    }
  }

  Future<void> _onCreateRequested(
    ev.TeamCreateRequested event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.copyWith(status: TeamStatus.loading));
    try {
      final team = await _teamApiService.createTeam(
        name: event.name,
        gameId: event.gameId,
        maxMembers: event.maxMembers,
        description: event.description,
        requiredRank: event.requiredRank,
      );
      _wsClient.subscribeRoom(team.id, 'team');
      emit(state.copyWith(status: TeamStatus.loaded, currentTeam: team, successMessage: 'Đã tạo nhóm!'));
      AppEventBus.instance.triggerProfileReload();
    } catch (e) {
      debugPrint('[TeamBloc] _onCreateRequested ERROR: $e');
      emit(state.copyWith(status: TeamStatus.error, errorMessage: 'Không thể tạo nhóm: $e'));
    }
  }

  Future<void> _onReadyToggled(
    ev.TeamReadyToggled event,
    Emitter<TeamState> emit,
  ) async {
    if (state.currentTeam == null) return;
    try {
      await _teamApiService.setReady(state.currentTeam!.id, event.ready);
    } catch (_) {}
  }

  Future<void> _onLeaveRequested(
    ev.TeamLeaveRequested event,
    Emitter<TeamState> emit,
  ) async {
    if (state.currentTeam == null) return;
    final teamId = state.currentTeam!.id;
    emit(state.copyWith(status: TeamStatus.loading));
    try {
      await _teamApiService.leaveTeam(teamId);
      _wsClient.unsubscribeRoom(teamId, 'team');
      emit(state.copyWith(status: TeamStatus.loaded, clearTeam: true, successMessage: 'Đã rời nhóm'));
      AppEventBus.instance.triggerProfileReload();
    } catch (e) {
      debugPrint('[TeamBloc] _onLeaveRequested ERROR: $e');
      emit(state.copyWith(status: TeamStatus.error, errorMessage: 'Không thể rời nhóm: $e'));
    }
  }

  Future<void> _onDisbandRequested(
    ev.TeamDisbandRequested event,
    Emitter<TeamState> emit,
  ) async {
    if (state.currentTeam == null) return;
    final teamId = state.currentTeam!.id;
    emit(state.copyWith(status: TeamStatus.loading));
    try {
      await _teamApiService.disbandTeam(teamId);
      _wsClient.unsubscribeRoom(teamId, 'team');
      emit(state.copyWith(status: TeamStatus.loaded, clearTeam: true, successMessage: 'Đã giải tán nhóm'));
      AppEventBus.instance.triggerProfileReload();
    } catch (e) {
      debugPrint('[TeamBloc] _onDisbandRequested ERROR: $e');
      emit(state.copyWith(status: TeamStatus.error, errorMessage: 'Không thể giải tán: $e'));
    }
  }

  Future<void> _onJoinRequestsLoadRequested(
    ev.TeamJoinRequestsLoadRequested event,
    Emitter<TeamState> emit,
  ) async {
    if (state.currentTeam == null) return;
    try {
      final requests = await _teamApiService.getJoinRequests(state.currentTeam!.id);
      emit(state.copyWith(joinRequests: requests));
    } catch (_) {}
  }

  Future<void> _onAcceptRequest(
    ev.JoinRequestAccepted event,
    Emitter<TeamState> emit,
  ) async {
    if (state.currentTeam == null) return;
    emit(state.copyWith(status: TeamStatus.loading));
    try {
      await _teamApiService.acceptJoinRequest(
        teamId: state.currentTeam!.id,
        requestId: event.requestId,
      );
      // Reload team to get updated member list
      final team = await _teamApiService.getMyTeam();
      if (team != null) {
        _wsClient.subscribeRoom(team.id, 'team');
      }
      emit(state.copyWith(
        status: TeamStatus.loaded,
        currentTeam: team,
        joinRequests: state.joinRequests.where((r) => r.id != event.requestId).toList(),
        successMessage: 'Đã chấp nhận thành viên',
      ));
    } catch (e) {
      debugPrint('[TeamBloc] _onAcceptRequest ERROR: $e');
      emit(state.copyWith(status: TeamStatus.loaded, errorMessage: 'Không thể chấp nhận: $e'));
    }
  }

  Future<void> _onRejectRequest(
    ev.JoinRequestRejected event,
    Emitter<TeamState> emit,
  ) async {
    if (state.currentTeam == null) return;
    try {
      await _teamApiService.rejectJoinRequest(
        teamId: state.currentTeam!.id,
        requestId: event.requestId,
      );
      emit(state.copyWith(
        joinRequests: state.joinRequests.where((r) => r.id != event.requestId).toList(),
        successMessage: 'Đã từ chối',
      ));
    } catch (e) {
      debugPrint('[TeamBloc] _onRejectRequest ERROR: $e');
      emit(state.copyWith(errorMessage: 'Không thể từ chối: $e'));
    }
  }

  Future<void> _onOpenTeamsLoadRequested(
    ev.TeamOpenLoadRequested event,
    Emitter<TeamState> emit,
  ) async {
    try {
      final teams = await _teamApiService.getOpenTeams(gameId: event.gameId);
      emit(state.copyWith(openTeams: teams));
    } catch (_) {}
  }

  Future<void> _onJoinRequestSent(
    ev.TeamJoinRequestSent event,
    Emitter<TeamState> emit,
  ) async {
    try {
      await _teamApiService.sendJoinRequest(event.teamId, message: event.message);
      emit(state.copyWith(successMessage: 'Đã gửi yêu cầu!'));
    } catch (e) {
      debugPrint('[TeamBloc] _onJoinRequestSent ERROR: $e');
      emit(state.copyWith(errorMessage: 'Không thể gửi yêu cầu: $e'));
    }
  }

  void _onMemberJoined(ev.TeamMemberJoinedEvent event, Emitter<TeamState> emit) async {
    if (state.currentTeam == null) return;
    // Reload entire team to ensure data consistency
    try {
      final team = await _teamApiService.getMyTeam();
      if (team != null) {
        _wsClient.subscribeRoom(team.id, 'team');
      }
      emit(state.copyWith(status: TeamStatus.loaded, currentTeam: team, clearTeam: team == null));
    } catch (e) {
      debugPrint('[TeamBloc] _onMemberJoined reload failed: $e');
    }
  }

  void _onMemberLeft(ev.TeamMemberLeftEvent event, Emitter<TeamState> emit) {
    if (state.currentTeam == null) return;
    final updatedMembers = state.currentTeam!.members
        .where((m) => m.userId != event.userId)
        .toList();
    emit(state.copyWith(
      currentTeam: TeamModel(
        id: state.currentTeam!.id,
        name: state.currentTeam!.name,
        gameId: state.currentTeam!.gameId,
        gameName: state.currentTeam!.gameName,
        maxMembers: state.currentTeam!.maxMembers,
        ownerId: state.currentTeam!.ownerId,
        ownerName: state.currentTeam!.ownerName,
        isRecruiting: state.currentTeam!.isRecruiting,
        members: updatedMembers,
        createdAt: state.currentTeam!.createdAt,
      ),
    ));
  }

  void _onMemberReady(ev.TeamMemberReadyEvent event, Emitter<TeamState> emit) {
    if (state.currentTeam == null) return;
    final updatedMembers = state.currentTeam!.members.map((m) {
      if (m.userId == event.userId) {
        return TeamMemberModel(
          id: m.id,
          userId: m.userId,
          displayName: m.displayName,
          avatarUrl: m.avatarUrl,
          role: m.role,
          isReady: event.isReady,
          isOnline: m.isOnline,
          isLeader: m.isLeader,
        );
      }
      return m;
    }).toList();
    emit(state.copyWith(
      currentTeam: TeamModel(
        id: state.currentTeam!.id,
        name: state.currentTeam!.name,
        gameId: state.currentTeam!.gameId,
        gameName: state.currentTeam!.gameName,
        maxMembers: state.currentTeam!.maxMembers,
        ownerId: state.currentTeam!.ownerId,
        ownerName: state.currentTeam!.ownerName,
        isRecruiting: state.currentTeam!.isRecruiting,
        members: updatedMembers,
        createdAt: state.currentTeam!.createdAt,
      ),
    ));
  }

  void _onTeamDisbanded(ev.TeamDisbandedEvent event, Emitter<TeamState> emit) {
    if (state.currentTeam != null) {
      _wsClient.unsubscribeRoom(state.currentTeam!.id, 'team');
    }
    emit(state.copyWith(clearTeam: true, successMessage: 'Nhóm đã bị giải tán'));
  }

  void _onJoinRequestCreated(ev.JoinRequestCreatedEvent event, Emitter<TeamState> emit) {
    final updated = [event.request, ...state.joinRequests];
    emit(state.copyWith(joinRequests: updated));
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _connSub?.cancel();
    _teamReloadSub?.cancel();
    return super.close();
  }
}
