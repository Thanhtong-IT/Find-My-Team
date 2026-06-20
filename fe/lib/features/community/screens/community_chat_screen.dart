import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/repository/secure_storage_repository.dart';
import '../models/community_model.dart';
import '../models/channel_model.dart';
import '../models/chat_message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../services/chat_api_service.dart';
import '../data/community_repository.dart';
import '../widgets/community_channel_drawer.dart';
import '../widgets/create_channel_dialog.dart';

class CommunityChatScreen extends StatefulWidget {
  final CommunityModel community;

  const CommunityChatScreen({super.key, required this.community});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  ChannelModel? _currentChannel;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoadingChannels = true;
  List<ChannelModel> _channels = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadChannels();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await SecureStorageRepository().getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  Future<void> _loadChannels() async {
    final channels = await CommunityRepository().getChannels(widget.community.id);
    if (mounted && channels.isNotEmpty) {
      final textChannels = channels.where((c) => c.type == ChannelType.text).toList();
      setState(() {
        _channels = channels;
        _currentChannel = textChannels.isNotEmpty ? textChannels.first : channels.first;
        _isLoadingChannels = false;
      });
    } else if (mounted) {
      setState(() {
        _channels = channels;
        _isLoadingChannels = false;
      });
    }
  }

  void _onChannelSelected(ChannelModel channel) {
    setState(() => _currentChannel = channel);
  }

  void _showCreateChannelDialog(BuildContext blocContext, ChannelType type) {
    final communityBloc = blocContext.read<CommunityBloc>();
    showDialog(
      context: blocContext,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: communityBloc,
          child: BlocListener<CommunityBloc, CommunityState>(
            listener: (listenerContext, state) {
              if (state.channelCreating == false && state.successMessage != null && state.errorMessage == null) {
                Navigator.pop(dialogCtx);
                _showSnackBar(state.successMessage!);
                _loadChannels();
              } else if (state.channelCreating == false && state.errorMessage != null) {
                _showSnackBar(state.errorMessage!, isError: true);
              }
            },
            child: CreateChannelDialog(
              initialType: type,
              onSubmit: (name, submittedType) {
                communityBloc.add(CommunityChannelCreateRequested(
                  communityId: widget.community.id,
                  name: name,
                  type: submittedType.name,
                ));
              },
              onCancel: () => Navigator.pop(dialogCtx),
            ),
          ),
        );
      },
    );
  }

  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentChannel == null) return;
    context.read<ChatBloc>().add(ChatSendMessageRequested(
      communityId: widget.community.id,
      channelId: _currentChannel!.id,
      content: text,
    ));
    _messageController.clear();
  }

  void _retryMessage(BuildContext context, String clientMessageId) {
    if (_currentChannel == null) return;
    context.read<ChatBloc>().add(ChatRetryMessageRequested(
      clientMessageId: clientMessageId,
      communityId: widget.community.id,
      channelId: _currentChannel!.id,
    ));
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? AppColors.error : AppColors.primary, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    if (_isLoadingChannels) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentChannel = _currentChannel;
    if (currentChannel == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textLight),
              const SizedBox(height: 16),
              const Text('Không có kênh nào', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadChannels,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChatBloc(chatApiService: ChatApiService())
            ..add(ChatMessagesLoadRequested(
              communityId: widget.community.id,
              channelId: currentChannel.id,
            )),
        ),
        BlocProvider(
          create: (_) => CommunityBloc()
            ..add(CommunityChannelsLoadRequested(widget.community.id)),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ChatBloc, ChatState>(
            listener: (context, state) {
              if (state.status == ChatStatus.error && state.errorMessage != null) {
                _showSnackBar(state.errorMessage!, isError: true);
              }
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          BlocListener<CommunityBloc, CommunityState>(
            listener: (context, state) {
              if (state.successMessage != null) {
                _showSnackBar(state.successMessage!);
              }
              if (state.errorMessage != null) {
                _showSnackBar(state.errorMessage!, isError: true);
              }
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: AppColors.white,
              drawer: Drawer(
                child: BlocBuilder<CommunityBloc, CommunityState>(
                  builder: (context, communityState) {
                    return CommunityChannelDrawer(
                      community: widget.community,
                      selectedChannel: currentChannel,
                      channels: communityState.channels.isNotEmpty ? communityState.channels : _channels,
                      isLoading: communityState.status == CommunityStatus.loading,
                      onChannelSelected: _onChannelSelected,
                      onCreateChannelPressed: (type) => _showCreateChannelDialog(context, type),
                    );
                  },
                ),
              ),
              body: Column(
                children: [
                  _buildAppBar(isSmallScreen, currentChannel),
                  Expanded(child: _buildMessageList(isSmallScreen)),
                  _buildInputBar(isSmallScreen, currentChannel),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isSmallScreen, ChannelModel currentChannel) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 0,
        right: 0,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Quay lại',
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Danh sách kênh',
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentChannel.type == ChannelType.text ? '# ' : '\uD83D\uDD0A ',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Flexible(
                    child: Text(
                      currentChannel.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            onPressed: () => _showSnackBar('Tính năng tìm kiếm sẽ được thêm sau'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
            onPressed: () => _showSnackBar('Tính năng cài đặt sẽ được thêm sau'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isSmallScreen) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state.status == ChatStatus.loading && state.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: isSmallScreen ? 56 : 64, color: AppColors.textLight),
                const SizedBox(height: 12),
                Text('Chưa có tin nhắn nào', style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Hãy là người đầu tiên gửi tin nhắn!', style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textLight)),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 12),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final msg = state.messages[index];
            final showDate = index == 0 || !_isSameDay(msg.timestamp, state.messages[index - 1].timestamp);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate) _buildDateDivider(msg.timestamp, isSmallScreen),
                _MessageBubble(
                  message: msg,
                  isSmallScreen: isSmallScreen,
                  currentUserId: _currentUserId,
                  onRetry: () => _retryMessage(context, msg.clientMessageId),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime date, bool isSmallScreen) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = 'Hôm nay';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Hôm qua';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.textLight)),
          ),
          Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildInputBar(bool isSmallScreen, ChannelModel currentChannel) {
    final channelPrefix = currentChannel.type == ChannelType.text ? '# ${currentChannel.name}' : currentChannel.name;
    return Container(
      padding: EdgeInsets.only(
        left: isSmallScreen ? 10 : 14,
        right: isSmallScreen ? 10 : 14,
        top: isSmallScreen ? 8 : 10,
        bottom: MediaQuery.of(context).padding.bottom + (isSmallScreen ? 8 : 10),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.textSecondary, size: isSmallScreen ? 24 : 26), onPressed: () => _showSnackBar('Tính năng đính kèm sẽ được thêm sau')),
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: isSmallScreen ? 100 : 120),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Gửi tin nhắn đến $channelPrefix',
                  hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textLight),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 14 : 18, vertical: isSmallScreen ? 10 : 12),
                ),
                onSubmitted: (_) => _sendMessage(context),
              ),
            ),
          ),
          IconButton(icon: Icon(Icons.emoji_emotions_outlined, color: AppColors.textSecondary, size: isSmallScreen ? 24 : 26), onPressed: () => _showSnackBar('Tính năng emoji sẽ được thêm sau')),
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.send_rounded, color: AppColors.primary, size: isSmallScreen ? 24 : 26),
              onPressed: () => _sendMessage(ctx),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSmallScreen;
  final String? currentUserId;
  final VoidCallback onRetry;

  const _MessageBubble({
    required this.message,
    required this.isSmallScreen,
    required this.currentUserId,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = currentUserId != null && message.senderId == currentUserId;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMe) const Spacer(flex: 1),
          CircleAvatar(
            radius: isSmallScreen ? 16 : 18,
            backgroundColor: _getAvatarColor(message.senderName),
            child: Text(
              message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.senderName,
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: AppColors.textLight),
                    ),
                    if (message.status == MessageStatus.sending) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                    if (message.status == MessageStatus.failed) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onRetry,
                        child: const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                      ),
                    ],
                    if (message.status == MessageStatus.sent && isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done, size: 14, color: AppColors.success),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (message.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                      child: Image.network(message.imageUrl!, errorBuilder: (ctx, err, stack) => const SizedBox()),
                    ),
                  ),
                if (message.content.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 14, vertical: isSmallScreen ? 7 : 9),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        color: isMe ? AppColors.white : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isMe) const Spacer(flex: 1),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [AppColors.primary, const Color(0xFF7C3AED), AppColors.success, const Color(0xFFF59E0B), const Color(0xFFEF4444)];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
