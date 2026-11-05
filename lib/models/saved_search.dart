class SavedSearch {
  final String id;
  final String profileId;
  final String name;
  final Map<String, dynamic> filter;
  final bool alertEnabled;
  final DateTime createdAt;

  SavedSearch({
    required this.id,
    required this.profileId,
    required this.name,
    required this.filter,
    required this.alertEnabled,
    required this.createdAt,
  });

  factory SavedSearch.fromMap(Map<String, dynamic> map) {
    return SavedSearch(
      id: map['id'].toString(),
      profileId: map['profile_id'].toString(),
      name: map['name']?.toString() ?? 'Untitled',
      filter:
          (map['filter_json'] as Map?)?.cast<String, dynamic>() ??
          (map['filter'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{},
      alertEnabled:
          (map['alert_enabled'] as bool?) ??
          (map['alertEnabled'] as bool?) ??
          false,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'profile_id': profileId,
    'name': name,
    'filter_json': filter,
    'alert_enabled': alertEnabled,
    'created_at': createdAt.toIso8601String(),
  };
}
