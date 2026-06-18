import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class OnlinePlayerModel {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? username;
  final String? gameName;
  final String? rank;
  final String? role;
  final bool isOnline;

  const OnlinePlayerModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.username,
    this.gameName,
    this.rank,
    this.role,
    this.isOnline = true,
  });

  factory OnlinePlayerModel.fromJson(Map<String, dynamic> json) {
    return OnlinePlayerModel(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName'] as String? ?? json['username'] as String? ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      username: json['username'] as String?,
      gameName: json['gameName'] as String?,
      rank: json['rank'] as String?,
      role: json['role'] as String?,
      isOnline: json['isOnline'] as bool? ?? json['online'] as bool? ?? true,
    );
  }
}

class ExploreApiService {
  Future<List<OnlinePlayerModel>> getOnlinePlayers({String? gameId, int limit = 20}) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (gameId != null) queryParams['gameId'] = gameId;

      final resp = await DioClient.get(
        ApiConstants.onlinePlayers,
        queryParameters: queryParams,
      );

      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        return [];
      }

      final list = json['data'] as List<dynamic>?;
      if (list == null) return [];

      return list.map((e) => OnlinePlayerModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}
