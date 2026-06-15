class UserModel {
  final String id; // Backend returns UUID as String, not int
  final String username;
  final String email;
  final String? fullName;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? region;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.region,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Backend returns 'userId' as UUID String, not 'id' as int
    final userIdStr = json['userId'] as String? ?? json['id']?.toString() ?? '0';
    return UserModel(
      id: userIdStr,
      username: json['username'] as String? ?? 'unknown',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      region: json['region'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'region': region,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get effectiveName => displayName ?? fullName ?? username;
}
