class User {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final DateTime createdAt;
  final List<String> favoriteContentIds;
  final List<String> watchLaterContentIds;
  final List<WatchHistory> watchHistory;
  final UserSubscription subscription;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.createdAt,
    this.favoriteContentIds = const [],
    this.watchLaterContentIds = const [],
    this.watchHistory = const [],
    required this.subscription,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      favoriteContentIds: List<String>.from(json['favoriteContentIds'] ?? []),
      watchLaterContentIds: List<String>.from(json['watchLaterContentIds'] ?? []),
      watchHistory: (json['watchHistory'] as List<dynamic>?)
              ?.map((e) => WatchHistory.fromJson(e))
              .toList() ??
          [],
      subscription: UserSubscription.fromJson(json['subscription']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'favoriteContentIds': favoriteContentIds,
      'watchLaterContentIds': watchLaterContentIds,
      'watchHistory': watchHistory.map((e) => e.toJson()).toList(),
      'subscription': subscription.toJson(),
    };
  }
}

class WatchHistory {
  final String contentId;
  final DateTime watchedAt;
  final int watchedDuration; // in seconds
  final int totalDuration; // in seconds

  WatchHistory({
    required this.contentId,
    required this.watchedAt,
    required this.watchedDuration,
    required this.totalDuration,
  });

  double get progress => watchedDuration / totalDuration;

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      contentId: json['contentId'],
      watchedAt: DateTime.parse(json['watchedAt']),
      watchedDuration: json['watchedDuration'],
      totalDuration: json['totalDuration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'watchedAt': watchedAt.toIso8601String(),
      'watchedDuration': watchedDuration,
      'totalDuration': totalDuration,
    };
  }
}

class UserSubscription {
  final String planId;
  final String planName;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final SubscriptionType type;

  UserSubscription({
    required this.planId,
    required this.planName,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.type,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      planId: json['planId'],
      planName: json['planName'],
      price: json['price'].toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'],
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => SubscriptionType.free,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'planName': planName,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'type': type.toString().split('.').last,
    };
  }
}

enum SubscriptionType {
  free,
  basic,
  premium,
  family,
}
