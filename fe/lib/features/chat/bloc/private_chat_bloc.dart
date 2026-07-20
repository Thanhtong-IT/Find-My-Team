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

    // 3. Gửi qua REST API (Thay thế cho WebSocket gửi trực tiếp để lấy ACK tức thì)
    try {
      final sentMessage = await _apiService.sendMessage(
        receiverId: _friendId,
        content: event.content,
        clientMessageId: clientMsgId,
      );

      // 4. Cập nhật trạng thái tin nhắn thành "sent" dựa trên phản hồi từ Server
      final updatedMessages = state.messages.map((m) {
        if (m.clientMessageId == clientMsgId) {
          // Ghi đè bằng dữ liệu thật từ server (có ID chính thức)
          return sentMessage.copyWith(status: PrivateMessageStatus.sent, isMe: true);
        }
        return m;
      }).toList();

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      // Nếu lỗi, đánh dấu failed
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

    // 1. Kiểm tra xem tin nhắn này đã tồn tại trong danh sách chưa (theo ID server hoặc Client ID)
    final isDuplicate = state.messages.any(
          (m) => (m.id != null && m.id == incoming.id) || 
                 (m.clientMessageId == incoming.clientMessageId && m.clientMessageId.isNotEmpty),
    );

    if (isDuplicate) {
      // Cập nhật lại tin nhắn nếu cần (ví dụ: chuyển từ sending sang sent)
      final updatedMessages = state.messages.map<PrivateMessage>((m) {
        if (m.clientMessageId == incoming.clientMessageId || (m.id != null && m.id == incoming.id)) {
          return incoming.copyWith(status: PrivateMessageStatus.sent, isMe: incoming.senderId == _currentUserId);
        }
        return m;
      }).toList();

      emit(state.copyWith(messages: updatedMessages));
    } else {
      // 2. Tin nhắn mới hoàn toàn từ người khác gửi đến
      final messageWithMe = incoming.copyWith(
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