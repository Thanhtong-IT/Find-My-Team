import 'package:equatable/equatable.dart';
import '../models/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatMessagesLoadRequested extends ChatEvent {
  final String communityId;
  final String channelId;
  final bool refresh;

  const ChatMessagesLoadRequested({
    required this.communityId,
    required this.channelId,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [communityId, channelId, refresh];
}

class ChatSendMessageRequested extends ChatEvent {
  final String communityId;
  final String channelId;
  final String content;
  final String? imageUrl;

  const ChatSendMessageRequested({
    required this.communityId,
    required this.channelId,
    required this.content,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [communityId, channelId, content, imageUrl];
}

class ChatRetryMessageRequested extends ChatEvent {
  final String clientMessageId;
  final String communityId;
  final String channelId;

  const ChatRetryMessageRequested({
    required this.clientMessageId,
    required this.communityId,
    required this.channelId,
  });

  @override
  List<Object?> get props => [clientMessageId, communityId, channelId];
}

class ChatMessageReceivedFromWebSocket extends ChatEvent {
  final ChatMessage message;
  const ChatMessageReceivedFromWebSocket(this.message);
  @override
  List<Object?> get props => [message];
}

class ChatMessageConfirmed extends ChatEvent {
  final String clientMessageId;
  final String serverMessageId;
  const ChatMessageConfirmed({required this.clientMessageId, required this.serverMessageId});
  @override
  List<Object?> get props => [clientMessageId, serverMessageId];
}

class ChatTypingStarted extends ChatEvent {
  final String channelId;
  const ChatTypingStarted(this.channelId);
  @override
  List<Object?> get props => [channelId];
}

class ChatTypingStopped extends ChatEvent {
  final String channelId;
  const ChatTypingStopped(this.channelId);
  @override
  List<Object?> get props => [channelId];
}

class ChatLoadMoreRequested extends ChatEvent {
  final String communityId;
  final String channelId;
  const ChatLoadMoreRequested({required this.communityId, required this.channelId});
  @override
  List<Object?> get props => [communityId, channelId];
}
