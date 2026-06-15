import 'package:equatable/equatable.dart';
import '../models/chat_message.dart';

enum ChatStatus { initial, loading, loaded, sending, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;
  final Set<String> typingUserIds;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.hasMore = true,
    this.currentPage = 0,
    this.errorMessage,
    this.typingUserIds = const {},
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    Set<String>? typingUserIds,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage,
      typingUserIds: typingUserIds ?? this.typingUserIds,
    );
  }

  @override
  List<Object?> get props => [status, messages, hasMore, currentPage, errorMessage, typingUserIds];
}
