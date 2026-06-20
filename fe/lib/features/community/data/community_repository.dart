import '../models/community_model.dart';
import '../models/channel_model.dart';
import '../models/message_model.dart';
import '../services/community_api_service.dart';

class CommunityRepository {
  static final CommunityRepository _instance = CommunityRepository._internal();
  factory CommunityRepository() => _instance;
  CommunityRepository._internal();

  final CommunityApiService _apiService = CommunityApiService();

  Future<List<CommunityModel>> getCommunities({String? gameId}) async {
    try {
      return await _apiService.getCommunities(gameId: gameId);
    } catch (e) {
      return [];
    }
  }

  Future<CommunityModel?> getCommunity(String id) async {
    try {
      final communities = await _apiService.getCommunities();
      return communities.where((c) => c.id == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  Future<CommunityModel> createCommunity({
    required String name,
    required String gameId,
    required String description,
    String? avatarUrl,
    required bool isPublic,
  }) async {
    return await _apiService.createCommunity(
      name: name,
      gameId: gameId,
      description: description,
      avatarUrl: avatarUrl ?? '',
      isPublic: isPublic,
    );
  }

  Future<List<ChannelModel>> getChannels(String communityId) async {
    try {
      final resp = await _apiService.getChannels(communityId);
      return resp;
    } catch (e) {
      return [];
    }
  }

  Future<ChannelModel> createChannel({
    required String communityId,
    required String name,
    required ChannelType type,
  }) async {
    return await _apiService.createChannel(
      communityId: communityId,
      name: name,
      type: type == ChannelType.text ? 'TEXT' : 'VOICE',
    );
  }

  List<MessageModel> getMessages(String channelId) {
    return [];
  }

  void addMessage(String channelId, MessageModel message) {
    // Chat functionality handled elsewhere
  }
}
