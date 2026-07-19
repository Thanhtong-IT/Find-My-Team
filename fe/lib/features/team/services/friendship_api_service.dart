import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/friendship_model.dart';

class FriendshipApiService {
  Future<FriendshipModel> sendFriendRequest(String userId) async {
    final resp = await DioClient.post(
      ApiConstants.friendships,
      data: {'userId': userId},
    );
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể gửi lời mời kết bạn',
      );
    }
    return FriendshipModel.fromJson(json['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    final resp = await DioClient.post('${ApiConstants.friendships}/$friendshipId/accept');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể chấp nhận lời mời',
      );
    }
  }

  Future<void> rejectFriendRequest(String friendshipId) async {
    final resp = await DioClient.post('${ApiConstants.friendships}/$friendshipId/reject');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể từ chối lời mời',
      );
    }
  }

  Future<void> cancelFriendRequest(String friendshipId) async {
    final resp = await DioClient.delete('${ApiConstants.friendships}/$friendshipId');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể hủy lời mời',
      );
    }
  }

  Future<void> unfriend(String friendshipId) async {
    final resp = await DioClient.delete('${ApiConstants.friendships}/$friendshipId/unfriend');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể hủy kết bạn',
      );
    }
  }

  Future<List<FriendshipModel>> getFriends() async {
    try {
      final resp = await DioClient.get('${ApiConstants.friendships}/friends');
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        return [];
      }
      final list = json['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<FriendshipModel>> getPendingRequests() async {
    try {
      final resp = await DioClient.get('${ApiConstants.friendships}/requests');
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        return [];
      }
      final list = json['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<FriendshipModel?> getFriendshipWith(String userId) async {
    try {
      final resp = await DioClient.get('${ApiConstants.friendships}/with/$userId');
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        return null;
      }
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return FriendshipModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
