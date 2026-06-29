import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/team_model.dart';

class TeamApiService {
  Future<TeamModel> createTeam({
    required String name,
    required String gameId,
    required int maxMembers,
    String? description,
    String? requiredRank,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'gameId': gameId,
      'maxSize': maxMembers,
    };
    if (description != null) data['description'] = description;
    if (requiredRank != null) data['requiredRank'] = requiredRank;
    final resp = await DioClient.post(
      ApiConstants.teams,
      data: data,
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions, message: json['message'] as String?);
    return TeamModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<TeamModel?> getMyTeam() async {
    try {
      final resp = await DioClient.get(ApiConstants.myTeam);
      final json = resp.data as Map<String, dynamic>;
      if (json['success'] != true) return null;
      final data = json['data'];
      if (data == null) return null;
      return TeamModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<TeamModel>> getOpenTeams({String? gameId}) async {
    final resp = await DioClient.get(
      ApiConstants.openTeams,
      queryParameters: gameId != null ? {'gameId': gameId} : null,
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
    final list = json['data'] as List<dynamic>;
    return list.map((e) => TeamModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TeamModel>> getRecruitingTeams({int limit = 5}) async {
    final resp = await DioClient.get(
      ApiConstants.recruitingTeams,
      queryParameters: {'limit': limit},
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
    final list = json['data'] as List<dynamic>;
    return list.map((e) => TeamModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setReady(String teamId, bool ready) async {
    final resp = await DioClient.put(
      '${ApiConstants.teams}/$teamId/ready',
      data: {'ready': ready},
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
  }

  Future<void> toggleMic(String teamId) async {
    final resp = await DioClient.put('${ApiConstants.teams}/$teamId/mic');
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
  }

  Future<void> leaveTeam(String teamId) async {
    final resp = await DioClient.post('${ApiConstants.teams}/$teamId/leave');
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
  }

  Future<void> disbandTeam(String teamId) async {
    final resp = await DioClient.delete('${ApiConstants.teams}/$teamId');
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
  }

  Future<List<JoinRequestModel>> getJoinRequests(String teamId) async {
    final resp = await DioClient.get('${ApiConstants.teams}/$teamId/join-requests');
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
    final list = json['data'] as List<dynamic>;
    return list.map((e) => JoinRequestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> acceptJoinRequest({required String teamId, required String requestId}) async {
    final resp = await DioClient.post('${ApiConstants.teams}/$teamId/join-requests/$requestId/accept');
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
  }

  Future<void> rejectJoinRequest({required String teamId, required String requestId}) async {
    final resp = await DioClient.post('${ApiConstants.teams}/$teamId/join-requests/$requestId/reject');
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
  }

  Future<void> sendJoinRequest(String teamId, {String? message}) async {
    final resp = await DioClient.post(
      '${ApiConstants.teams}/$teamId/join-requests',
      data: message != null ? {'message': message} : null,
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
  }

  Future<void> kickMember({required String teamId, required String memberId}) async {
    final resp = await DioClient.delete('${ApiConstants.teams}/$teamId/members/$memberId');
    final json = resp.data as Map<String, dynamic>;
    if (json['success'] != true) throw DioException(requestOptions: resp.requestOptions);
  }
}
