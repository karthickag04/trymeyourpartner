class Profile {
  final String userId;
  final String name;
  final String gender;
  final String phone;
  final String email;
  final String? imageUrl;

  const Profile({
    required this.userId,
    required this.name,
    required this.gender,
    required this.phone,
    required this.email,
    this.imageUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] ?? json['auth_user_id'] ?? json['id'],
      name: json['name'] ?? json['full_name'] ?? '',
      gender: json['gender'] ?? '',
      phone: json['phone'] ?? json['mobile'] ?? '',
      email: json['email'] ?? '',
      imageUrl:
          json['profile_image_url'] ??
          json['profile_picture_url'] ??
          json['avatar_url'] ??
          json['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'gender': gender,
    'phone': phone,
    'email': email,
    if (imageUrl != null) 'profile_image_url': imageUrl,
  };
}
