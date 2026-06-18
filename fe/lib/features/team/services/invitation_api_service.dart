import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/invitation_model.dart';

class InvitationApiService {
  Future<List<InvitationModel>> getReceivedInvitations() async {
    try {
      final resp = await DioClient.get(ApiConstants.invitationsReceived);
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        return [];
      }
      final list = json['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => InvitationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<InvitationModel>> getSentInvitations() async {
    try {
      final resp = await DioClient.get(ApiConstants.invitationsSent);
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        return [];
      }
      final list = json['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => InvitationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<InvitationModel> createInvitation({
    required String inviteeId,
    required String teamId,
    String? message,
  }) async {
    final data = <String, dynamic>{
      'inviteeId': inviteeId,
      'teamId': teamId,
    };
    if (message != null) data['message'] = message;
    final resp = await DioClient.post(
      ApiConstants.invitations,
      data: data,
    );
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tạo lời mời',
      );
    }
    return InvitationModel.fromJson(json['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> acceptInvitation(String invitationId) async {
    final resp = await DioClient.post('${ApiConstants.invitations}/$invitationId/accept');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể chấp nhận lời mời',
      );
    }
  }

  Future<void> rejectInvitation(String invitationId) async {
    final resp = await DioClient.post('${ApiConstants.invitations}/$invitationId/reject');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể từ chối lời mời',
      );
    }
  }
}
