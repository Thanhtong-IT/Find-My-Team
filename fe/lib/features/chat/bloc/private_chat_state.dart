part of 'private_chat_bloc.dart';

enum PrivateChatStatus { initial, loading, loaded, error }

class PrivateChatState extends Equatable {
  final PrivateChatStatus status;
  final List<PrivateMessage> messages;
  final int currentPage;
  final bool hasReachedMax;
  final String? errorMessage;

  const PrivateChatState({
    this.status = PrivateChatStatus.initial,
    this.messages = const [],
    this.currentPage = 0,
    this.hasReachedMax = false,
    this.errorMessage,
  });

  PrivateChatState copyWith({
    PrivateChatStatus? status,
    List<PrivateMessage>? messages,
    int? currentPage,
    bool? hasReachedMax,
    String? errorMessage,
  }) {
    return PrivateChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, currentPage, hasReachedMax, errorMessage];
}
