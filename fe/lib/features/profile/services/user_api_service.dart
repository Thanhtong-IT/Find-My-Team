import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/profile_model.dart';
import '../models/game_model.dart';

class UserApiException implements Exception {
  final String message;

  const UserApiException(this.message);

  @override
  String toString() => message;
}

class AvatarUploadTarget {
  final String uploadUrl;
  final String publicUrl;
  final String objectKey;
  final int expiresInSeconds;

  const AvatarUploadTarget({
    required this.uploadUrl,
    required this.publicUrl,
    required this.objectKey,
    required this.expiresInSeconds,
  });

  factory AvatarUploadTarget.fromJson(Map<String, dynamic> json) {
    return AvatarUploadTarget(
      uploadUrl: json['uploadUrl'] as String? ?? '',
      publicUrl: json['publicUrl'] as String? ?? '',
      objectKey: json['objectKey'] as String? ?? '',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 300,
    );
  }
}

class UserSearchResult {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isOnline;
  final UserGameProfileModel? gameProfile;

  const UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.gameProfile,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    UserGameProfileModel? gp;
    if (json['gameProfile'] != null) {
      gp = UserGameProfileModel.fromJson(json['gameProfile'] as Map<String, dynamic>);
    }
    return UserSearchResult(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['username'] as String? ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      gameProfile: gp,
    );
  }
}

class UserApiService {
  Future<List<GameModel>> getPopularGames() async {
    try {
      final resp = await DioClient.get(ApiConstants.popularGames);
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) throw Exception();
      final list = json['data'] as List<dynamic>?;
      if (list == null) return _mockGames;
      return list.map((e) => GameModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _mockGames;
    }
  }

  Future<UserProfileModel> getMyProfile() async {
    final resp = await DioClient.get(ApiConstants.userProfile);
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tải profile',
      );
    }
    return UserProfileModel.fromJson(json['data'] as Map<String, dynamic>? ?? {});
  }

  Future<UserProfileModel> getUserProfile(String userId) async {
    final url = ApiConstants.userProfileById.replaceFirst('{userId}', userId);
    final resp = await DioClient.get(url);
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tải profile người dùng',
      );
    }
    return UserProfileModel.fromJson(json['data'] as Map<String, dynamic>? ?? {});
  }

  Future<AvatarUploadTarget> createAvatarUploadUrl(String contentType) async {
    final resp = await DioClient.post(
      ApiConstants.avatarUploadUrl,
      data: {'contentType': contentType},
    );
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tạo URL upload avatar',
      );
    }
    return AvatarUploadTarget.fromJson(json['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> uploadAvatarToPresignedUrl({
    required String uploadUrl,
    required String contentType,
    required List<int> bytes,
  }) async {
    final dio = Dio(BaseOptions(
      headers: {'Content-Type': contentType, 'Accept': '*/*'},
      followRedirects: false,
      validateStatus: (status) => status != null && status < 500,
    ));
    final response = await dio.put(
      uploadUrl,
      data: bytes,
      options: Options(headers: {'Content-Type': contentType}),
    );
    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Không thể tải avatar lên R2',
        response: response,
      );
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? region,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (bio != null) data['bio'] = bio;
    if (region != null) data['region'] = region;

    final resp = await DioClient.put(ApiConstants.userProfile, data: data);
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể cập nhật profile',
      );
    }
  }

  Future<void> updateGameProfiles(List<GameProfileUpdateItem> profiles) async {
    final resp = await DioClient.put(
      ApiConstants.userGameProfiles,
      data: {
        'profiles': profiles.map((profile) => profile.toJson()).toList(),
      },
    );
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể cập nhật game profile',
      );
    }
  }

  Future<void> verifyRiotAccount({
    required String profileId,
    required String riotGameName,
    required String riotTagLine,
    required String region,
  }) async {
    try {
      final resp = await DioClient.post(
        '${ApiConstants.addGameProfile}/$profileId/riot/verify',
        data: {
          'riotGameName': riotGameName,
          'riotTagLine': riotTagLine,
          'region': region,
        },
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw UserApiException(json?['message'] as String? ?? 'Không thể xác thực Riot account');
      }
    } on DioException catch (e) {
      throw UserApiException(_extractErrorMessage(e, 'Không thể xác thực Riot account'));
    }
  }

  Future<void> refreshRiotAccount(String profileId) async {
    try {
      final resp = await DioClient.post('${ApiConstants.addGameProfile}/$profileId/riot/refresh');
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw UserApiException(json?['message'] as String? ?? 'Không thể đồng bộ Riot account');
      }
    } on DioException catch (e) {
      throw UserApiException(_extractErrorMessage(e, 'Không thể đồng bộ Riot account'));
    }
  }

  Future<void> unlinkRiotAccount(String profileId) async {
    try {
      final resp = await DioClient.delete('${ApiConstants.addGameProfile}/$profileId/riot');
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw UserApiException(json?['message'] as String? ?? 'Không thể gỡ liên kết Riot account');
      }
    } on DioException catch (e) {
      throw UserApiException(_extractErrorMessage(e, 'Không thể gỡ liên kết Riot account'));
    }
  }

  Future<UserGameProfileModel> addGameProfile({
    required String gameId,
    String? rank,
    String? role,
  }) async {
    final data = <String, dynamic>{
      'gameId': gameId,
    };
    if (rank != null) data['rank'] = rank;
    if (role != null) data['role'] = role;
    final resp = await DioClient.post(
      ApiConstants.addGameProfile,
      data: data,
    );
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể thêm game profile',
      );
    }
    return UserGameProfileModel.fromJson(json['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> deleteGameProfile(String profileId) async {
    final resp = await DioClient.delete('${ApiConstants.addGameProfile}/$profileId');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể xóa game profile',
      );
    }
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final resp = await DioClient.get(
        ApiConstants.explore,
        queryParameters: {'q': query, 'limit': 20},
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        return [];
      }
      final list = json['data'] as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  String _extractErrorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (error.type != DioExceptionType.badResponse) {
      final message = error.message;
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}

final _mockGames = [
  const GameModel(id: '1', name: 'Liên Minh Huyền Thoại', description: 'Game MOBA phổ biến nhất Việt Nam', ranks: ['Sắt', 'Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Cao Thủ', 'Thách Đấu'], roles: ['Đỡ Đòn', 'Xạ Thủ', 'Pháp Sư', 'Sát Thủ', 'Hỗ Trợ', 'Trợ Thủ']),
  const GameModel(id: '2', name: 'Valorant', description: 'FPS tactical shooter', ranks: ['Sắt', 'Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Cao Thủ', 'Thách Đấu'], roles: ['Duelist', 'Controller', 'Sentinel', 'Initiator']),
  const GameModel(id: '3', name: 'Liên Quân Mobile', description: 'MOBA mobile phổ biến', ranks: ['Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Cao Thủ', 'Thách Đấu'], roles: ['Đỡ Đòn', 'Xạ Thủ', 'Pháp Sư', 'Sát Thủ', 'Hỗ Trợ']),
  const GameModel(id: '4', name: 'PUBG Mobile', description: 'Battle royale mobile', ranks: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Crown', 'Ace', 'Conqueror'], roles: ['AR', 'SMG', 'SR', 'Sniper', 'IGL']),
  const GameModel(id: '5', name: 'Genshin Impact', description: 'Open world RPG', ranks: [], roles: ['DPS', 'Support', 'Healer', 'Shielder']),
];
