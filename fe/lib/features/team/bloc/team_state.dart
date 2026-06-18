import 'package:equatable/equatable.dart';
import '../models/team_model.dart';
import '../models/invitation_model.dart';

enum TeamStatus { initial, loading, loaded, error }

class TeamState extends Equatable {
  final TeamStatus status;
  final TeamModel? currentTeam;
  final List<JoinRequestModel> joinRequests;
  final List<TeamModel> openTeams;
  final List<InvitationModel> receivedInvitations;
  final List<InvitationModel> sentInvitations;
  final String? errorMessage;
  final String? successMessage;

  const TeamState({
    this.status = TeamStatus.initial,
    this.currentTeam,
    this.joinRequests = const [],
    this.openTeams = const [],
    this.receivedInvitations = const [],
    this.sentInvitations = const [],
    this.errorMessage,
    this.successMessage,
  });

  TeamState copyWith({
    TeamStatus? status,
    TeamModel? currentTeam,
    List<JoinRequestModel>? joinRequests,
    List<TeamModel>? openTeams,
    List<InvitationModel>? receivedInvitations,
    List<InvitationModel>? sentInvitations,
    String? errorMessage,
    String? successMessage,
    bool clearTeam = false,
  }) {
    return TeamState(
      status: status ?? this.status,
      currentTeam: clearTeam ? null : (currentTeam ?? this.currentTeam),
      joinRequests: joinRequests ?? this.joinRequests,
      openTeams: openTeams ?? this.openTeams,
      receivedInvitations: receivedInvitations ?? this.receivedInvitations,
      sentInvitations: sentInvitations ?? this.sentInvitations,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get hasTeam => currentTeam != null;

  @override
  List<Object?> get props => [status, currentTeam, joinRequests, openTeams, receivedInvitations, sentInvitations, errorMessage, successMessage];
}
