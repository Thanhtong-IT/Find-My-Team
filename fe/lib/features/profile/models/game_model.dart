class GameModel {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? gradientStart;
  final String? gradientEnd;
  final List<String> ranks;
  final List<String> roles;

  const GameModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.gradientStart,
    this.gradientEnd,
    this.ranks = const [],
    this.roles = const [],
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      gradientStart: json['gradientStart'] as String?,
      gradientEnd: json['gradientEnd'] as String?,
      ranks: (json['ranks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
