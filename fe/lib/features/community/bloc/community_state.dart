import 'package:equatable/equatable.dart';
import '../models/community_model.dart';
import '../models/channel_model.dart';

enum CommunityStatus { initial, loading, loaded, error }

class CommunityState extends Equatable {
  final CommunityStatus status;
  final List<CommunityModel> communities;
  final List<ChannelModel> channels;
  final String? errorMessage;
  final String? successMessage;

  const CommunityState({
    this.status = CommunityStatus.initial,
    this.communities = const [],
    this.channels = const [],
    this.errorMessage,
    this.successMessage,
  });

  CommunityState copyWith({
    CommunityStatus? status,
    List<CommunityModel>? communities,
    List<ChannelModel>? channels,
    String? errorMessage,
    String? successMessage,
  }) {
    return CommunityState(
      status: status ?? this.status,
      communities: communities ?? this.communities,
      channels: channels ?? this.channels,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, communities, channels, errorMessage, successMessage];
}
