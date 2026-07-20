import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/private_message.dart';
import '../services/private_chat_api_service.dart';
import '../services/private_chat_websocket_service.dart';

part 'private_chat_event.dart';
part 'private_chat_state.dart';

class PrivateChatBloc extends Bloc<PrivateChatEvent, PrivateChatState> {
  final PrivateChatApiService _apiService;
  final PrivateChatWebSocketService _wsService;
  final String _friendId;
  final String _currentUserId;
  StreamSubscription? _wsSubscription;

  PrivateChatBloc({
    required PrivateChatApiService apiService,
    required PrivateChatWebSocketService wsService,
    required String friendId,
    required String currentUserId,
  })  : _apiService = apiService,
        _wsService = wsService,
        _friendId = friendId,
        _currentUserId = currentUserId,
        super(const PrivateChatState()) {
    on<PrivateChatHistoryLoadRequested>(_onHistoryLoadRequested);
    on<PrivateChatSendMessageRequested>(_onSendMessageRequested);
    on<PrivateChatRealtimeMessageReceived>(_onRealtimeMessageReceived);

    _listenWebSocket();
  }

  void _listenWebSocket() {
    _wsSubscription = _wsService.onMessageReceived.listen((message) {
      add(PrivateChatRealtimeMessageReceived(message));
    });
  }

  Future<void> _onHistoryLoadRequested(
    PrivateChatHistoryLoadRequested event,
    Emitter<PrivateChatState> emit,
  ) async {
    if (event.isRefresh) {
      emit(state.copyWith(status: PrivateChatStatus.loading, messages: []));
    }

    try {
      final messages = await _apiService.getChatHistory(
        friendId: _friendId,
        page: event.isRefresh ? 0 : state.currentPage + 1,
        currentUserId: _currentUserId,
      );

      final isLastPage = messages.length < 20;

      emit(state.copyWith(
        status: PrivateChatStatus.loaded,
        messages: event.isRefresh ? messages : [...state.messages, ...messages],
        currentPage: event.isRefresh ? 0 : state.currentPage + 1,
        hasReachedMax: isLastPage,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrivateChatStatus.error,
        errorMessage: 'Không thể tải lịch sử chat: $e',
      ));
    }
  }

  Future<void> _onSendMessageRequested(
    PrivateChatSendMessageRequested event,
    Emitter<PrivateChatState> emit,
  ) async {
    final clientMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 1. Optimistic UI: Tạo tin nhắn tạm thời
    final tempMessage = PrivateMessage(
      clientMessageId: clientMsgId,
      senderId: _currentUserId,
      receiverId: _friendId,
      content: event.content,
      timestamp: DateTime.now(),
      status: PrivateMessageStatus.sending,
      isMe: true,
    );

    // 2. Cập nhật state ngay lập tức với trạng thái "sending"
    emit(state.copyWith(
      messages: [tempMessage, ...state.messages],
    ));

    // 3. Gửi qua WebSocket
    try {
      _wsService.sendRealtimeMessage(
        receiverId: _friendId,
        content: event.content,
        clientMessageId: clientMsgId,
      );
    } catch (e) {
      // Nếu gửi WebSocket lỗi, đánh dấu failed
      emit(state.copyWith(
        messages: state.messages.map((m) {
          return m.clientMessageId == clientMsgId 
              ? m.copyWith(status: PrivateMessageStatus.failed) 
              : m;
        }).toList(),
      ));
    }
  }

  void _onRealtimeMessageReceived(
    PrivateChatRealtimeMessageReceived event,
    Emitter<PrivateChatState> emit,
  ) {
    final incoming = event.message;
    
    // Check if this is a confirmation of a message we sent
    final index = state.messages.indexWhere(
      (m) => m.clientMessageId == incoming.clientMessageId,
    );

    if (index != -1) {
      // Cập nhật tin nhắn đang ở trạng thái "sending" thành "sent"
      final updatedMessages = state.messages.map((m) {
        if (m.clientMessageId == incoming.clientMessageId) {
          return incoming.copyWith(status: PrivateMessageStatus.sent);
        }
        return m;
      }).toList();
      
      emit(state.copyWith(messages: updatedMessages));
    } else {
      // Tin nhắn mới từ bạn bè, chèn vào đầu danh sách
      // Đảm bảo set isMe chính xác dựa trên currentUserId
      final messageWithMe = PrivateMessage(
        id: incoming.id,
        clientMessageId: incoming.clientMessageId,
        senderId: incoming.senderId,
        receiverId: incoming.receiverId,
        content: incoming.content,
        timestamp: incoming.timestamp,
        status: PrivateMessageStatus.sent,
        isMe: incoming.senderId == _currentUserId,
      );
      
      emit(state.copyWith(
        messages: [messageWithMe, ...state.messages],
      ));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
