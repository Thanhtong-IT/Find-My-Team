import 'package:equatable/equatable.dart';
import '../models/community_model.dart';
import '../models/channel_model.dart';

enum CommunityStatus { initial, loading, loaded, error }

class CommunityState extends Equatable {
  final CommunityStatus status;
  final List<CommunityModel> communities;
  final List<ChannelModel> channels;
  final bool channelCreating;
  final String? errorMessage;
  final String? successMessage;

  const CommunityState({
    this.status = CommunityStatus.initial,
    this.communities = const [],
    this.channels = const [],
    this.channelCreating = false,
    this.errorMessage,
    this.successMessage,
  });

  CommunityState copyWith({
    CommunityStatus? status,
    List<CommunityModel>? communities,
    List<ChannelModel>? channels,
    bool? channelCreating,
    String? errorMessage,
    String? successMessage,
  }) {
    return CommunityState(
      status: status ?? this.status,
      communities: communities ?? this.communities,
      channels: channels ?? this.channels,
      channelCreating: channelCreating ?? this.channelCreating,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, communities, channels, channelCreating, errorMessage, successMessage];
}
