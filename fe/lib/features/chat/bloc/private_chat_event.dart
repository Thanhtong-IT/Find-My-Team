part of 'private_chat_bloc.dart';

abstract class PrivateChatEvent extends Equatable {
  const PrivateChatEvent();
  @override
  List<Object?> get props => [];
}

class PrivateChatHistoryLoadRequested extends PrivateChatEvent {
  final String friendId;
  final bool isRefresh;
  const PrivateChatHistoryLoadRequested(this.friendId, {this.isRefresh = true});

  @override
  List<Object?> get props => [friendId, isRefresh];
}

class PrivateChatSendMessageRequested extends PrivateChatEvent {
  final String content;
  const PrivateChatSendMessageRequested(this.content);

  @override
  List<Object?> get props => [content];
}

class PrivateChatRealtimeMessageReceived extends PrivateChatEvent {
  final PrivateMessage message;
  const PrivateChatRealtimeMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}
