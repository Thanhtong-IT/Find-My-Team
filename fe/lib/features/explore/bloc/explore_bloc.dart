import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/events/event_bus.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import 'explore_event.dart';
import 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  StreamSubscription? _wsSub;

  ExploreBloc() : super(const ExploreState()) {
    on<ExploreLoadRequested>(_onLoadRequested);
    on<ExploreSwipeRequested>(_onSwipeRequested);
    on<ExploreMatchReceived>(_onMatchReceived);

    _listenWebSocket();
  }

  void _listenWebSocket() {
    _wsSub = AppEventBus.instance.matchStream.listen((event) {
      final match = MatchModel.fromJson(event.data);
      add(ExploreMatchReceived(
        matchId: match.id,
        otherUserName: match.matchedUserName,
      ));
    });
  }

  Future<void> _onLoadRequested(
    ExploreLoadRequested event,
    Emitter<ExploreState> emit,
  ) async {
    emit(state.copyWith(status: ExploreStatus.loading));
    try {
      final params = <String, dynamic>{};
      if (event.gameId != null) params['game'] = event.gameId;
      if (event.query != null && event.query!.isNotEmpty) params['q'] = event.query;

      final resp = await DioClient.get(ApiConstants.onlinePlayers, queryParameters: params);
      final json = resp.data as Map<String, dynamic>;
      if (json['success'] != true) throw Exception();

      final players = (json['data'] as List<dynamic>)
          .map((e) => OnlinePlayer.fromJson(e as Map<String, dynamic>))
          .toList();

      emit(state.copyWith(
        status: ExploreStatus.loaded,
        onlinePlayers: players,
        selectedGameId: event.gameId,
        query: event.query,
      ));
    } catch (e) {
      emit(state.copyWith(status: ExploreStatus.error, errorMessage: 'Lỗi tải dữ liệu'));
    }
  }

  Future<void> _onSwipeRequested(
    ExploreSwipeRequested event,
    Emitter<ExploreState> emit,
  ) async {
    emit(state.copyWith(status: ExploreStatus.swiping));
    try {
      await DioClient.post(
        ApiConstants.swipes,
        data: {
          'targetUserId': event.targetUserId,
          'liked': event.liked,
        },
      );
      emit(state.copyWith(status: ExploreStatus.loaded));
    } catch (e) {
      emit(state.copyWith(status: ExploreStatus.loaded, errorMessage: 'Lỗi swipe'));
    }
  }

  void _onMatchReceived(
    ExploreMatchReceived event,
    Emitter<ExploreState> emit,
  ) {
    emit(state.copyWith(newMatch: MatchModel(
      id: event.matchId,
      matchedUserId: 0,
      matchedUserName: event.otherUserName,
      matchedAt: DateTime.now(),
    )));
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
