import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants/constants.dart';
import '../../../core/repository/secure_storage_repository.dart';
import '../bloc/private_chat_bloc.dart';
import '../models/private_message.dart';
import '../services/private_chat_api_service.dart';
import '../services/private_chat_websocket_service.dart';
import '../../../core/di/injection.dart';

class PrivateChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String? friendAvatar;

  const PrivateChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatar,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _storage = SecureStorageRepository();
  final _wsService = getIt<PrivateChatWebSocketService>();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _currentUserId;
  String? _token;

  @override
  void initState() {
    super.initState();
    _initAndConnect();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initAndConnect() async {
    final userId = await _storage.getUserId();
    final token = await _storage.getAccessToken();

    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _token = token;
      });

      if (token != null && userId != null) { 
        final baseUrl = dotenv.env['API_BASE_URL']?.replaceAll('/api', '') ??
            'https://findmyteam.q2k.click';
            
        _wsService.connect(
          baseUrl: baseUrl, 
          token: token, 
          currentUserId: userId!,
);
      }
    }
  }

  void _onScroll() {
    // Khi cuộn gần lên đỉnh (pixels lớn vì reverse: true)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      // Trình AI context: Bloc được bọc qua BlocProvider ở dưới, cần lấy qua context của View
    }
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null || _token == null) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider(
      create: (context) => PrivateChatBloc(
        apiService: PrivateChatApiService(),
        wsService: getIt<PrivateChatWebSocketService>(),
        friendId: widget.friendId,
        currentUserId: _currentUserId!,
      )..add(PrivateChatHistoryLoadRequested(widget.friendId, isRefresh: true)),
      child: _PrivateChatView(
        friendName: widget.friendName,
        friendAvatar: widget.friendAvatar,
        textController: _textController,
        scrollController: _scrollController,
        friendId: widget.friendId,
      ),
    );
  }
}

class _PrivateChatView extends StatelessWidget {
  final String friendName;
  final String? friendAvatar;
  final TextEditingController textController;
  final ScrollController scrollController;
  final String friendId;

  const _PrivateChatView({
    required this.friendName,
    this.friendAvatar,
    required this.textController,
    required this.scrollController,
    required this.friendId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: friendAvatar != null && friendAvatar!.isNotEmpty
                  ? NetworkImage(friendAvatar!)
                  : null,
              child: friendAvatar == null || friendAvatar!.isEmpty
                  ? const Icon(Icons.person, size: 20, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friendName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.videocam_rounded)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<PrivateChatBloc, PrivateChatState>(
              builder: (context, state) {
                if (state.status == PrivateChatStatus.loading && state.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == PrivateChatStatus.error && state.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(state.errorMessage ?? 'Không thể tải tin nhắn'),
                        TextButton(
                          onPressed: () => context
                              .read<PrivateChatBloc>()
                              .add(PrivateChatHistoryLoadRequested(friendId)),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = state.messages;

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length + (state.hasReachedMax ? 0 : 1),
                  reverse: true, // Tin nhắn mới nhất ở dưới
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      // Trigger load more
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final bloc = context.read<PrivateChatBloc>();
                        if (!state.hasReachedMax && state.status != PrivateChatStatus.loading) {
                          bloc.add(PrivateChatHistoryLoadRequested(friendId, isRefresh: false));
                        }
                      });
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    final message = messages[index];
                    return _MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) => _sendMessage(context),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _sendMessage(context),
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final text = textController.text.trim();
    if (text.isNotEmpty) {
      context.read<PrivateChatBloc>().add(PrivateChatSendMessageRequested(text));
      textController.clear();
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final PrivateMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                const CircleAvatar(
                  radius: 14,
                  child: Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : const Color(0xFFE9E9EB),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                _buildStatusIcon(),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 40,
              right: isMe ? 22 : 0,
            ),
            child: Text(
              _formatTimestamp(message.timestamp),
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case PrivateMessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
          ),
        );
      case PrivateMessageStatus.failed:
        return const Icon(Icons.error_rounded, size: 16, color: AppColors.error);
      case PrivateMessageStatus.sent:
      default:
        return const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.textLight);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }
}
