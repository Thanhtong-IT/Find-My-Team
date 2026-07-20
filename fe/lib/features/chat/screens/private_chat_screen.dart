import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/repository/secure_storage_repository.dart';
import '../bloc/private_chat_bloc.dart';
import '../services/private_chat_api_service.dart';
import '../services/private_chat_websocket_service.dart';

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
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await _storage.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (context) => PrivateChatBloc(
        apiService: PrivateChatApiService(),
        wsService: PrivateChatWebSocketService(), // Note: needs to be connected elsewhere or here
        friendId: widget.friendId,
        currentUserId: _currentUserId!,
      )..add(PrivateChatHistoryLoadRequested(widget.friendId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.friendName),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
        ),
        body: const Center(child: Text('Chat screen content will be here')),
      ),
    );
  }
}
