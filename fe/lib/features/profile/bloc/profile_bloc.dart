import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/events/event_bus.dart';
import '../services/user_api_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserApiService _userApiService;
  StreamSubscription? _profileReloadSub;

  ProfileBloc({required UserApiService userApiService})
      : _userApiService = userApiService,
        super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<GameProfileAddRequested>(_onAddGameProfile);
    on<GameProfileDeleteRequested>(_onDeleteGameProfile);
    on<PopularGamesLoadRequested>(_onLoadPopularGames);

    _listenProfileReload();
  }

  void _listenProfileReload() {
    _profileReloadSub = AppEventBus.instance.profileReloadStream.listen((_) {
      add(const ProfileLoadRequested());
    });
  }

  @override
  Future<void> close() {
    _profileReloadSub?.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _userApiService.getMyProfile();
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Không thể tải hồ sơ: $e',
      ));
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      await _userApiService.updateProfile(
        displayName: event.displayName,
        bio: event.bio,
        region: event.region,
      );
      final profile = await _userApiService.getMyProfile();
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Không thể cập nhật hồ sơ: $e',
      ));
    }
  }

  Future<void> _onAddGameProfile(
    GameProfileAddRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      await _userApiService.addGameProfile(
        gameId: event.gameId,
        rank: event.rank,
        role: event.role,
      );
      final profile = await _userApiService.getMyProfile();
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Không thể thêm game profile: $e',
      ));
    }
  }

  Future<void> _onDeleteGameProfile(
    GameProfileDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      await _userApiService.deleteGameProfile(event.profileId);
      final profile = await _userApiService.getMyProfile();
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Không thể xóa game profile: $e',
      ));
    }
  }

  Future<void> _onLoadPopularGames(
    PopularGamesLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final games = await _userApiService.getPopularGames();
      emit(state.copyWith(popularGames: games));
    } catch (_) {}
  }
}
