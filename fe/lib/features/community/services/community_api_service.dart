import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/community_model.dart';
import '../models/channel_model.dart';

class CommunityApiService {
  Future<List<CommunityModel>> getCommunities({String? gameId}) async {
    final resp = await DioClient.get(
      ApiConstants.communities,
      queryParameters: gameId != null ? {'gameId': gameId} : null,
    );
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tải danh sách cộng đồng',
      );
    }
    final list = json['data'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => CommunityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ChannelModel>> getChannels(String communityId) async {
    final resp = await DioClient.get('${ApiConstants.communities}/$communityId/channels');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tải danh sách kênh',
      );
    }
    final list = json['data'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => ChannelModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CommunityModel> createCommunity({
    required String name,
    required String gameId,
    required String description,
    required String avatarUrl,
    required bool isPublic,
  }) async {
    final resp = await DioClient.post(
      ApiConstants.communities,
      data: {
        'name': name,
        'gameId': gameId,
        'description': description,
        'avatarUrl': avatarUrl,
        'isPublic': isPublic,
      },
    );
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tạo cộng đồng',
      );
    }
    return CommunityModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> joinCommunity(String communityId) async {
    final resp = await DioClient.post('${ApiConstants.communities}/$communityId/join');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tham gia cộng đồng',
      );
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    final resp = await DioClient.post('${ApiConstants.communities}/$communityId/leave');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể rời cộng đồng',
      );
    }
  }

  Future<ChannelModel> createChannel({
    required String communityId,
    required String name,
    required String type,
  }) async {
    final resp = await DioClient.post(
      '${ApiConstants.communities}/$communityId/channels',
      data: {
        'name': name,
        'type': type,
      },
    );
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tạo kênh',
      );
    }
    return ChannelModel.fromJson(json['data'] as Map<String, dynamic>);
  }
}
