class InvitationModel {
  final String id;
  final String inviterId;
  final String inviterName;
  final String? inviterAvatarUrl;
  final String? inviteeId;
  final String? inviteeName;
  final String? teamId;
  final String? teamName;
  final String type; // "team_invite" hoặc "friend_invite"
  final String status; // "pending", "accepted", "rejected"
  final String? message;
  final DateTime createdAt;

  const InvitationModel({
    required this.id,
    required this.inviterId,
    required this.inviterName,
    this.inviterAvatarUrl,
    this.inviteeId,
    this.inviteeName,
    this.teamId,
    this.teamName,
    required this.type,
    required this.status,
    this.message,
    required this.createdAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id']?.toString() ?? '',
      inviterId: json['inviterId']?.toString() ?? json['inviter_id']?.toString() ?? '',
      inviterName: json['inviterName'] as String? ?? json['inviter_name'] as String? ?? 'Unknown',
      inviterAvatarUrl: json['inviterAvatarUrl'] as String? ?? json['inviter_avatar_url'] as String?,
      inviteeId: json['inviteeId']?.toString() ?? json['invitee_id']?.toString(),
      inviteeName: json['inviteeName'] as String? ?? json['invitee_name'] as String?,
      teamId: json['teamId']?.toString() ?? json['team_id']?.toString(),
      teamName: json['teamName'] as String? ?? json['team_name'] as String?,
      type: json['type'] as String? ?? 'team_invite',
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isTeamInvite => type == 'team_invite';
}
