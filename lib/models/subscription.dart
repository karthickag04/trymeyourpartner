enum PlanTier { free, gold, platinum }

class Subscription {
  final String id; // row id in DB
  final String profileId; // owning matrimonial profile id
  final PlanTier tier;
  final DateTime startAt;
  final DateTime? endAt; // null means open-ended (till you marry)

  const Subscription({
    required this.id,
    required this.profileId,
    required this.tier,
    required this.startAt,
    required this.endAt,
  });

  bool get isActive {
    final now = DateTime.now();
    return startAt.isBefore(now) && (endAt == null || endAt!.isAfter(now));
  }

  int get activeMonths {
    final to = endAt ?? DateTime.now();
    final months = (to.year - startAt.year) * 12 + (to.month - startAt.month);
    return months <= 0 ? 1 : months;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'profile_id': profileId,
    'tier': tier.name,
    'start_at': startAt.toIso8601String(),
    'end_at': endAt?.toIso8601String(),
  };

  static Subscription fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String,
    profileId: json['profile_id'] as String,
    tier: _tierFromString(json['tier'] as String?),
    startAt: DateTime.parse(json['start_at'] as String),
    endAt: json['end_at'] != null
        ? DateTime.parse(json['end_at'] as String)
        : null,
  );

  static PlanTier _tierFromString(String? s) {
    switch (s) {
      case 'gold':
        return PlanTier.gold;
      case 'platinum':
        return PlanTier.platinum;
      case 'free':
      default:
        return PlanTier.free;
    }
  }
}

class PlanRules {
  // Assumptions (configurable):
  // - Free: 5 contact reveals per calendar month.
  // - Gold: 3m=20, 6m=40, 12m=unlimited, TYM=unlimited.
  // - Platinum: 3m=40, 6m=80, 12m=unlimited, TYM=unlimited.
  // Highlight & promotion: Platinum only.

  static int freeMonthlyContactLimit = 5; // editable in code

  static bool getHighlight(PlanTier tier) => tier == PlanTier.platinum;
  static bool getPromotion(PlanTier tier) => tier == PlanTier.platinum;

  static int? contactLimitFor(
    PlanTier tier,
    DateTime startAt,
    DateTime? endAt,
  ) {
    if (tier == PlanTier.free) return freeMonthlyContactLimit; // monthly window

    // Paid plans depend on total duration in months
    final months = _diffInWholeMonths(startAt, endAt);
    if (months <= 3) {
      return tier == PlanTier.gold ? 20 : 40;
    } else if (months <= 6) {
      return tier == PlanTier.gold ? 40 : 80;
    } else if (months <= 12) {
      return null; // unlimited for 12 months
    } else {
      return null; // treat >12 or till-you-marry as unlimited
    }
  }

  static int _diffInWholeMonths(DateTime start, DateTime? end) {
    final e = end ?? DateTime(start.year, start.month + 12, start.day);
    int months = (e.year - start.year) * 12 + (e.month - start.month);
    if (months <= 0) months = 1;
    return months;
  }
}
