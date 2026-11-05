class LocationData {
  final String id;
  final String name;
  final String? type; // optionally derived: 'state' or 'district'
  final String? parentId; // for districts, this is the state ID
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LocationData({
    required this.id,
    required this.name,
    this.type,
    this.parentId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    // Derive sensible defaults for missing fields in reference tables
    final derivedType = json.containsKey('state_id')
        ? 'district'
        : (json.containsKey('type') ? json['type'] : 'state');
    final parent = json['parent_id'] ?? json['state_id'];
    final created = json['created_at'];
    final updated = json['updated_at'];

    return LocationData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: derivedType?.toString(),
      parentId: parent?.toString(),
      isActive: (json['is_active'] is bool)
          ? json['is_active'] as bool
          : (json['is_active']?.toString().toLowerCase() == 'true'),
      createdAt: created is String ? DateTime.tryParse(created) : null,
      updatedAt: updated is String ? DateTime.tryParse(updated) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'parent_id': parentId,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class CasteData {
  final String id;
  final String name;
  final String? parentId; // for sub-castes
  final String? religion;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CasteData({
    required this.id,
    required this.name,
    this.parentId,
    this.religion,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CasteData.fromJson(Map<String, dynamic> json) {
    return CasteData(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      religion: json['religion'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'religion': religion,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
