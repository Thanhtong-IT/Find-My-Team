import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/profile_model.dart';
import '../models/game_model.dart';

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

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? region,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
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
}

// ─── Mock data ────────────────────────────────────────────────────────────────

final _mockGames = [
  const GameModel(id: '1', name: 'Liên Minh Huyền Thoại', description: 'Game MOBA phổ biến nhất Việt Nam', ranks: ['Sắt', 'Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Cao Thủ', 'Thách Đấu'], roles: ['Đỡ Đòn', 'Xạ Thủ', 'Pháp Sư', 'Sát Thủ', 'Hỗ Trợ', 'Trợ Thủ']),
  const GameModel(id: '2', name: 'Valorant', description: 'FPS tactical shooter', ranks: ['Sắt', 'Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Cao Thủ', 'Thách Đấu'], roles: ['Duelist', 'Controller', 'Sentinel', 'Initiator']),
  const GameModel(id: '3', name: 'Liên Quân Mobile', description: 'MOBA mobile phổ biến', ranks: ['Đồng', 'Bạc', 'Vàng', 'Bạch Kim', 'Kim Cương', 'Cao Thủ', 'Thách Đấu'], roles: ['Đỡ Đòn', 'Xạ Thủ', 'Pháp Sư', 'Sát Thủ', 'Hỗ Trợ']),
  const GameModel(id: '4', name: 'PUBG Mobile', description: 'Battle royale mobile', ranks: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Crown', 'Ace', 'Conqueror'], roles: ['AR', 'SMG', 'SR', 'Sniper', 'IGL']),
  const GameModel(id: '5', name: 'Genshin Impact', description: 'Open world RPG', ranks: [], roles: ['DPS', 'Support', 'Healer', 'Shielder']),
];


