import '../models/community_model.dart';
import '../models/channel_model.dart';
import '../models/message_model.dart';

class CommunityRepository {
  static final CommunityRepository _instance = CommunityRepository._internal();
  factory CommunityRepository() => _instance;
  CommunityRepository._internal() {
    _initDefaults();
  }

  final List<CommunityModel> _communities = [];
  final Map<String, List<ChannelModel>> _channels = {};
  final Map<String, List<MessageModel>> _messages = {};

  void _initDefaults() {
    _communities.addAll([
      CommunityModel(
        id: 'c1',
        name: 'Liên Minh Đại Chiến',
        game: 'Liên Minh Huyền Thoại',
        description: 'Cộng đồng chơi Liên Minh Huyền Thoại, leo rank và giao lưu.',
        isPublic: true,
        memberCount: 1200,
        onlineCount: 450,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      CommunityModel(
        id: 'c2',
        name: 'PUBG VN',
        game: 'PUBG Mobile',
        description: 'Cộng đồng PUBG Việt Nam, săn winner cùng nhau.',
        isPublic: true,
        memberCount: 850,
        onlineCount: 220,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      CommunityModel(
        id: 'c3',
        name: 'Valorant Elite',
        game: 'Valorant',
        description: 'Cộng đồng game thủ Valorant chuyên nghiệp.',
        isPublic: true,
        memberCount: 2400,
        onlineCount: 650,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ]);

    for (final community in _communities) {
      _channels[community.id] = [
        ChannelModel(id: '${community.id}_ch1', name: 'chung', type: ChannelType.text, communityId: community.id, createdAt: DateTime.now()),
        ChannelModel(id: '${community.id}_ch2', name: 'tìm-đội-rank', type: ChannelType.text, communityId: community.id, createdAt: DateTime.now()),
        ChannelModel(id: '${community.id}_ch3', name: 'trao-đổi-chiến-thuật', type: ChannelType.text, communityId: community.id, createdAt: DateTime.now()),
        ChannelModel(id: '${community.id}_vc1', name: 'Phòng chờ', type: ChannelType.voice, communityId: community.id, onlineCount: 0, createdAt: DateTime.now()),
        ChannelModel(id: '${community.id}_vc2', name: 'Rank Kim Cương+', type: ChannelType.voice, communityId: community.id, onlineCount: 0, createdAt: DateTime.now()),
      ];
    }

    for (final community in _communities) {
      final defaultChannel = _channels[community.id]?.first;
      if (defaultChannel != null) {
        _messages[defaultChannel.id] = _buildMockMessages(defaultChannel.id);
      }
    }
  }

  List<MessageModel> _buildMockMessages(String channelId) {
    final now = DateTime.now();
    return [
      MessageModel(id: '${channelId}_m1', senderId: 'u1', senderName: 'DragonSlayer', content: 'Mọi người ơi, tối nay ai rank cùng không?', timestamp: now.subtract(const Duration(hours: 2))),
      MessageModel(id: '${channelId}_m2', senderId: 'u2', senderName: 'PhantomX', content: 'Mình rank Bạch Kim, bạn rank gì vậy?', timestamp: now.subtract(const Duration(hours: 1, minutes: 50))),
      MessageModel(id: '${channelId}_m3', senderId: 'u1', senderName: 'DragonSlayer', content: 'Mình Kim Cương, chơi mid/top thì sao?', timestamp: now.subtract(const Duration(hours: 1, minutes: 40))),
      MessageModel(id: '${channelId}_m4', senderId: 'u3', senderName: 'NightHawk', content: 'Mình rank Cao thủ, bạn nào cần support không?', timestamp: now.subtract(const Duration(hours: 1, minutes: 20))),
      MessageModel(id: '${channelId}_m5', senderId: 'u4', senderName: 'StormBreaker', content: 'Chào mọi người! Mình mới join cộng đồng, rất vui được gặp mọi người.', timestamp: now.subtract(const Duration(minutes: 45))),
      MessageModel(id: '${channelId}_m6', senderId: 'u2', senderName: 'PhantomX', content: 'Chào bạn StormBreaker! Chào mừng đến với cộng đồng nha.', timestamp: now.subtract(const Duration(minutes: 30))),
    ];
  }

  Future<CommunityModel> createCommunity({required String name, required String game, required String description, String? avatarPath, String? coverPath, required bool isPublic}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final community = CommunityModel(id: 'c_${DateTime.now().millisecondsSinceEpoch}', name: name, game: game, description: description, avatarPath: avatarPath, coverPath: coverPath, isPublic: isPublic, memberCount: 1, onlineCount: 1, createdAt: DateTime.now());
    _communities.add(community);
    _channels[community.id] = [ChannelModel(id: '${community.id}_ch1', name: 'chung', type: ChannelType.text, communityId: community.id, createdAt: DateTime.now())];
    return community;
  }

  Future<ChannelModel> createChannel({required String communityId, required String name, required ChannelType type}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final channel = ChannelModel(id: '${communityId}_${type.name}_${DateTime.now().millisecondsSinceEpoch}', name: name, type: type, communityId: communityId, createdAt: DateTime.now());
    _channels.putIfAbsent(communityId, () => []);
    _channels[communityId]!.add(channel);
    if (type == ChannelType.text) _messages[channel.id] = [];
    return channel;
  }

  List<CommunityModel> getCommunities() => List.unmodifiable(_communities);
  CommunityModel? getCommunity(String id) { try { return _communities.firstWhere((c) => c.id == id); } catch (_) { return null; } }
  List<ChannelModel> getChannels(String communityId) => List.unmodifiable(_channels[communityId] ?? []);
  List<MessageModel> getMessages(String channelId) => List.unmodifiable(_messages[channelId] ?? []);
  void addMessage(String channelId, MessageModel message) { _messages.putIfAbsent(channelId, () => []); _messages[channelId]!.add(message); }
}
