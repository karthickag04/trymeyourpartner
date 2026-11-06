enum ContactRequestStatus { pending, accepted, declined, cancelled }

extension ContactRequestStatusX on ContactRequestStatus {
  String get value => switch (this) {
    ContactRequestStatus.pending => 'pending',
    ContactRequestStatus.accepted => 'accepted',
    ContactRequestStatus.declined => 'declined',
    ContactRequestStatus.cancelled => 'cancelled',
  };

  static ContactRequestStatus parse(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'accepted':
        return ContactRequestStatus.accepted;
      case 'declined':
        return ContactRequestStatus.declined;
      case 'cancelled':
        return ContactRequestStatus.cancelled;
      case 'pending':
      default:
        return ContactRequestStatus.pending;
    }
  }
}

/// Aggregate status between two profiles.
enum ContactHandshakeStatus {
  none,
  sentPending,
  receivedPending,
  accepted,
  declined,
  cancelled,
}

class ContactRequest {
  final String id;
  final String requesterProfileId;
  final String targetProfileId;
  final ContactRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;

  ContactRequest({
    required this.id,
    required this.requesterProfileId,
    required this.targetProfileId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
  });

  factory ContactRequest.fromMap(Map<String, dynamic> map) {
    return ContactRequest(
      id: (map['id'] ?? '').toString(),
      requesterProfileId:
          (map['requester_profile_id'] ?? map['requesterId'] ?? '').toString(),
      targetProfileId: (map['target_profile_id'] ?? map['targetId'] ?? '')
          .toString(),
      status: ContactRequestStatusX.parse(map['status']?.toString()),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      acceptedAt: map['accepted_at'] != null
          ? DateTime.tryParse(map['accepted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requester_profile_id': requesterProfileId,
      'target_profile_id': targetProfileId,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
    };
  }
}
