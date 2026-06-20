import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/channel_model.dart';
import '../services/community_api_service.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityApiService _apiService;

  CommunityBloc({CommunityApiService? apiService})
      : _apiService = apiService ?? CommunityApiService(),
        super(const CommunityState()) {
    on<CommunityLoadRequested>(_onLoadRequested);
    on<CommunityCreateRequested>(_onCreateRequested);
    on<CommunityJoinRequested>(_onJoinRequested);
    on<CommunityLeaveRequested>(_onLeaveRequested);
    on<CommunityChannelsLoadRequested>(_onChannelsLoadRequested);
    on<CommunityChannelCreateRequested>(_onChannelCreateRequested);
  }

  Future<void> _onLoadRequested(
    CommunityLoadRequested event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));
    try {
      final communities = await _apiService.getCommunities(gameId: event.gameId);
      emit(state.copyWith(status: CommunityStatus.loaded, communities: communities));
    } catch (e) {
      emit(state.copyWith(status: CommunityStatus.error, errorMessage: 'Không thể tải danh sách cộng đồng'));
    }
  }

  Future<void> _onCreateRequested(
    CommunityCreateRequested event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading));
    try {
      final community = await _apiService.createCommunity(
        name: event.name,
        gameId: event.gameId,
        description: event.description,
        avatarUrl: event.avatarUrl,
        isPublic: event.isPublic,
      );
      emit(state.copyWith(
        status: CommunityStatus.loaded,
        communities: [community, ...state.communities],
        successMessage: 'Đã tạo cộng đồng!',
      ));
    } catch (e) {
      emit(state.copyWith(status: CommunityStatus.error, errorMessage: 'Không thể tạo cộng đồng'));
    }
  }

  Future<void> _onJoinRequested(
    CommunityJoinRequested event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _apiService.joinCommunity(event.communityId);
      final updated = state.communities.map((c) {
        if (c.id == event.communityId) {
          return c.copyWith(memberCount: c.memberCount + 1);
        }
        return c;
      }).toList();
      emit(state.copyWith(communities: updated, successMessage: 'Đã tham gia cộng đồng'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể tham gia cộng đồng'));
    }
  }

  Future<void> _onLeaveRequested(
    CommunityLeaveRequested event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      await _apiService.leaveCommunity(event.communityId);
      final updated = state.communities.map((c) {
        if (c.id == event.communityId && c.memberCount > 0) {
          return c.copyWith(memberCount: c.memberCount - 1);
        }
        return c;
      }).toList();
      emit(state.copyWith(communities: updated, successMessage: 'Đã rời cộng đồng'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể rời cộng đồng'));
    }
  }

  Future<void> _onChannelsLoadRequested(
    CommunityChannelsLoadRequested event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final resp = await DioClient.get('${ApiConstants.communities}/${event.communityId}/channels');
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw DioException(
          requestOptions: resp.requestOptions,
          message: json?['message'] as String? ?? 'Không thể tải danh sách kênh',
        );
      }
      final list = json['data'] as List<dynamic>? ?? [];
      final channels = list.map((e) => ChannelModel.fromJson(e as Map<String, dynamic>)).toList();
      emit(state.copyWith(channels: channels));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Không thể tải danh sách kênh'));
    }
  }

  Future<void> _onChannelCreateRequested(
    CommunityChannelCreateRequested event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(channelCreating: true));
    try {
      final channel = await _apiService.createChannel(
        communityId: event.communityId,
        name: event.name,
        type: event.type,
      );
      emit(state.copyWith(
        channelCreating: false,
        channels: [...state.channels, channel],
        successMessage: 'Đã tạo kênh #${channel.name}',
      ));
    } catch (e) {
      emit(state.copyWith(
        channelCreating: false,
        errorMessage: 'Không thể tạo kênh',
      ));
    }
  }
}
