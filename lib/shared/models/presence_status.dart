class PresenceStatus {
  final bool isOnline;
  final DateTime? lastActiveAt;

  const PresenceStatus({required this.isOnline, this.lastActiveAt});

  factory PresenceStatus.fromJson(Map<String, dynamic> json) {
    return PresenceStatus(
      isOnline:
          (json['is_online'] as bool?) ?? (json['online'] as bool?) ?? false,
      lastActiveAt: _parseDateTime(
        json['last_active_at'] ?? json['lastActiveAt'],
      ),
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }
}
