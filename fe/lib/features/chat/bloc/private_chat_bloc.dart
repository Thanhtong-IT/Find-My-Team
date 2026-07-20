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
    // TỐI ƯU 1: Chống gọi trùng lặp nhiều lần khi đang load dở trang cũ
    if (state.status == PrivateChatStatus.loading && !event.isRefresh) return;
    if (state.hasReachedMax && !event.isRefresh) return;

    final targetPage = event.isRefresh ? 0 : state.currentPage + 1;

    emit(state.copyWith(
      status: PrivateChatStatus.loading,
      messages: event.isRefresh ? [] : state.messages,
    ));

    try {
      final messages = await _apiService.getChatHistory(
        friendId: _friendId,
        page: targetPage,
        currentUserId: _currentUserId,
      );

      final isLastPage = messages.length < 20;

      // TỐI ƯU 2: Lọc bỏ những tin nhắn đã vô tình được thêm qua luồng realtime trước đó để tránh trùng lặp UI
      final existingIds = state.messages.map((m) => m.id).toSet();
      final filteredNewMessages = messages.where((m) => !existingIds.contains(m.id)).toList();

      emit(state.copyWith(
        status: PrivateChatStatus.loaded,
        messages: event.isRefresh ? messages : [...state.messages, ...filteredNewMessages],
        currentPage: targetPage,
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
    if (event.content.trim().isEmpty) return;

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
      // Nếu gửi WebSocket lỗi đột xuất, đánh dấu failed lập tức
      final failedMessages = state.messages.map((m) {
        return m.clientMessageId == clientMsgId
            ? m.copyWith(status: PrivateMessageStatus.failed)
            : m;
      }).toList();

      emit(state.copyWith(messages: failedMessages));
    }
  }

  void _onRealtimeMessageReceived(
      PrivateChatRealtimeMessageReceived event,
      Emitter<PrivateChatState> emit,
      ) {
    final incoming = event.message;

    final index = state.messages.indexWhere(
          (m) => m.clientMessageId == incoming.clientMessageId,
    );

    if (index != -1) {
      // Cập nhật tin nhắn đang ở trạng thái "sending" thành "sent"
      final updatedMessages = state.messages.map<PrivateMessage>((m) {
  if (m.clientMessageId == incoming.clientMessageId) {
    return incoming.copyWith(status: PrivateMessageStatus.sent, isMe: true);
  }
  return m;
}).toList();

      emit(state.copyWith(messages: updatedMessages));
    } else {
      // Tin nhắn mới từ đối phương hoặc thiết bị khác của chính mình gửi
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