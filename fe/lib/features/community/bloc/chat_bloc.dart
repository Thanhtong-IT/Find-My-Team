import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/events/event_bus.dart';
import '../models/chat_message.dart';
import '../services/chat_api_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatApiService _chatApiService;
  StreamSubscription? _wsSub;

  ChatBloc({required ChatApiService chatApiService})
      : _chatApiService = chatApiService,
        super(const ChatState()) {
    on<ChatMessagesLoadRequested>(_onLoadRequested);
    on<ChatSendMessageRequested>(_onSendRequested);
    on<ChatRetryMessageRequested>(_onRetryRequested);
    on<ChatMessageReceivedFromWebSocket>(_onMessageReceived);
    on<ChatMessageConfirmed>(_onMessageConfirmed);
    on<ChatTypingStarted>(_onTypingStarted);
    on<ChatTypingStopped>(_onTypingStopped);
    on<ChatLoadMoreRequested>(_onLoadMore);

    _listenWebSocket();
  }

  void _listenWebSocket() {
    _wsSub = AppEventBus.instance.messageStream.listen((event) {
      final msg = ChatMessage.fromJson(event.data);
      add(ChatMessageReceivedFromWebSocket(msg));
    });
  }

  Future<void> _onLoadRequested(
    ChatMessagesLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final result = await _chatApiService.getMessages(
        communityId: event.communityId,
        channelId: event.channelId,
        page: event.refresh ? 0 : 0,
      );
      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: result.content,
        hasMore: !result.last,
        currentPage: result.page,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Không thể tải tin nhắn: $e',
      ));
    }
  }

  Future<void> _onSendRequested(
    ChatSendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final clientId = _chatApiService.generateClientMessageId();
    final tempMsg = ChatMessage(
      clientMessageId: clientId,
      senderId: 'me',
      senderName: 'Bạn',
      content: event.content,
      imageUrl: event.imageUrl,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    emit(state.copyWith(
      status: ChatStatus.sending,
      messages: [...state.messages, tempMsg],
    ));

    try {
      final confirmed = await _chatApiService.sendMessage(
        communityId: event.communityId,
        channelId: event.channelId,
        clientMessageId: clientId,
        content: event.content,
        imageUrl: event.imageUrl,
      );

      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: state.messages.map((m) {
          if (m.clientMessageId == clientId) {
            return confirmed.copyWith(status: MessageStatus.sent);
          }
          return m;
        }).toList(),
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: state.messages.map((m) {
          if (m.clientMessageId == clientId) {
            return m.copyWith(status: MessageStatus.failed);
          }
          return m;
        }).toList(),
      ));
    }
  }

  Future<void> _onRetryRequested(
    ChatRetryMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final msg = state.messages.firstWhere(
      (m) => m.clientMessageId == event.clientMessageId,
      orElse: () => throw Exception('Message not found'),
    );

    emit(state.copyWith(
      messages: state.messages.map((m) {
        if (m.clientMessageId == event.clientMessageId) {
          return m.copyWith(status: MessageStatus.sending);
        }
        return m;
      }).toList(),
    ));

    try {
      final confirmed = await _chatApiService.sendMessage(
        communityId: event.communityId,
        channelId: event.channelId,
        clientMessageId: event.clientMessageId,
        content: msg.content,
        imageUrl: msg.imageUrl,
      );
      emit(state.copyWith(
        messages: state.messages.map((m) {
          if (m.clientMessageId == event.clientMessageId) {
            return confirmed.copyWith(status: MessageStatus.sent);
          }
          return m;
        }).toList(),
      ));
    } catch (_) {
      emit(state.copyWith(
        messages: state.messages.map((m) {
          if (m.clientMessageId == event.clientMessageId) {
            return m.copyWith(status: MessageStatus.failed);
          }
          return m;
        }).toList(),
      ));
    }
  }

  void _onMessageReceived(
    ChatMessageReceivedFromWebSocket event,
    Emitter<ChatState> emit,
  ) {
    final incoming = event.message;
    final index = state.messages.indexWhere(
      (m) => m.clientMessageId == incoming.clientMessageId,
    );

    if (index != -1) {
      emit(state.copyWith(
        messages: state.messages.map((m) {
          if (m.clientMessageId == incoming.clientMessageId) {
            return m.copyWith(
              serverMessageId: incoming.serverMessageId,
              status: MessageStatus.sent,
            );
          }
          return m;
        }).toList(),
      ));
    } else {
      emit(state.copyWith(
        messages: [...state.messages, incoming],
      ));
    }
  }

  void _onMessageConfirmed(
    ChatMessageConfirmed event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(
      messages: state.messages.map((m) {
        if (m.clientMessageId == event.clientMessageId) {
          return m.copyWith(
            serverMessageId: event.serverMessageId,
            status: MessageStatus.sent,
          );
        }
        return m;
      }).toList(),
    ));
  }

  void _onTypingStarted(ChatTypingStarted event, Emitter<ChatState> emit) {}

  void _onTypingStopped(ChatTypingStopped event, Emitter<ChatState> emit) {}

  Future<void> _onLoadMore(
    ChatLoadMoreRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (!state.hasMore) return;
    try {
      final result = await _chatApiService.getMessages(
        communityId: event.communityId,
        channelId: event.channelId,
        page: state.currentPage + 1,
      );
      emit(state.copyWith(
        messages: [...result.content, ...state.messages],
        hasMore: !result.last,
        currentPage: state.currentPage + 1,
      ));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
