class MatrimonialUser {
  final String id;
  final String profileId;
  final String name;
  final String email;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String gender; // 'Male' or 'Female'
  final DateTime dateOfBirth;
  final String religion;
  final String caste;
  final String subCaste;
  final String state;
  final String district;
  final String city;
  final String education;
  final String occupation;
  final String workingLocation;
  final double? annualIncome;
  final String maritalStatus;
  final String? aboutMe;
  final String? familyDetails;
  final String? partnerPreferences;
  final List<String> hobbies;
  final List<String> languages;
  final double? height; // in cm
  final double? weight; // in kg
  final String? physicalDisability;
  final bool isActive;
  final bool isVerified;
  final bool isProfileComplete;
  final List<String> photoUrls;
  final ContactInfo contactInfo;
  final FamilyInfo familyInfo;
  final PartnerPreference partnerPreference;
  final List<String> shortlistedProfiles;
  final List<String> blockedProfiles;
  final List<String> viewedProfiles;
  final List<String> viewedByProfiles;
  final int totalViews;
  final int totalInterests;
  final DateTime? lastActiveAt;

  MatrimonialUser({
    required this.id,
    required this.profileId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.gender,
    required this.dateOfBirth,
    required this.religion,
    required this.caste,
    this.subCaste = '',
    required this.state,
    required this.district,
    required this.city,
    required this.education,
    required this.occupation,
    required this.workingLocation,
    this.annualIncome,
    required this.maritalStatus,
    this.aboutMe,
    this.familyDetails,
    this.partnerPreferences,
    this.hobbies = const [],
    this.languages = const [],
    this.height,
    this.weight,
    this.physicalDisability,
    this.isActive = true,
    this.isVerified = false,
    this.isProfileComplete = false,
    this.photoUrls = const [],
    required this.contactInfo,
    required this.familyInfo,
    required this.partnerPreference,
    this.shortlistedProfiles = const [],
    this.blockedProfiles = const [],
    this.viewedProfiles = const [],
    this.viewedByProfiles = const [],
    this.totalViews = 0,
    this.totalInterests = 0,
    this.lastActiveAt,
  });

  MatrimonialUser copyWith({
    String? id,
    String? profileId,
    String? name,
    String? email,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gender,
    DateTime? dateOfBirth,
    String? religion,
    String? caste,
    String? subCaste,
    String? state,
    String? district,
    String? city,
    String? education,
    String? occupation,
    String? workingLocation,
    double? annualIncome,
    String? maritalStatus,
    String? aboutMe,
    String? familyDetails,
    String? partnerPreferences,
    List<String>? hobbies,
    List<String>? languages,
    double? height,
    double? weight,
    String? physicalDisability,
    bool? isActive,
    bool? isVerified,
    bool? isProfileComplete,
    List<String>? photoUrls,
    ContactInfo? contactInfo,
    FamilyInfo? familyInfo,
    PartnerPreference? partnerPreference,
    List<String>? shortlistedProfiles,
    List<String>? blockedProfiles,
    List<String>? viewedProfiles,
    List<String>? viewedByProfiles,
    int? totalViews,
    int? totalInterests,
    DateTime? lastActiveAt,
  }) {
    return MatrimonialUser(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      religion: religion ?? this.religion,
      caste: caste ?? this.caste,
      subCaste: subCaste ?? this.subCaste,
      state: state ?? this.state,
      district: district ?? this.district,
      city: city ?? this.city,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      workingLocation: workingLocation ?? this.workingLocation,
      annualIncome: annualIncome ?? this.annualIncome,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      aboutMe: aboutMe ?? this.aboutMe,
      familyDetails: familyDetails ?? this.familyDetails,
      partnerPreferences: partnerPreferences ?? this.partnerPreferences,
      hobbies: hobbies ?? this.hobbies,
      languages: languages ?? this.languages,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      physicalDisability: physicalDisability ?? this.physicalDisability,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      photoUrls: photoUrls ?? this.photoUrls,
      contactInfo: contactInfo ?? this.contactInfo,
      familyInfo: familyInfo ?? this.familyInfo,
      partnerPreference: partnerPreference ?? this.partnerPreference,
      shortlistedProfiles: shortlistedProfiles ?? this.shortlistedProfiles,
      blockedProfiles: blockedProfiles ?? this.blockedProfiles,
      viewedProfiles: viewedProfiles ?? this.viewedProfiles,
      viewedByProfiles: viewedByProfiles ?? this.viewedByProfiles,
      totalViews: totalViews ?? this.totalViews,
      totalInterests: totalInterests ?? this.totalInterests,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  String get displayName => name.split(' ').first;

  String get heightInFeetInches {
    if (height == null) return 'Not specified';
    final totalInches = height! / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return '${feet}\'${inches}"';
  }

  factory MatrimonialUser.fromJson(Map<String, dynamic> json) {
    // Normalize differing backend field names and shapes
    String? _stringish(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map) {
        return v['name']?.toString() ?? v['id']?.toString();
      }
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        if (first is String) return first;
        if (first is Map)
          return first['name']?.toString() ?? first['id']?.toString();
      }
      return v.toString();
    }

    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      dynamic s = v;
      if (s is List && s.isNotEmpty) s = s.first;
      if (s is Map && s.isNotEmpty) s = (s.values).first;
      if (s is String) {
        final parsed = DateTime.tryParse(s);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    final heightVal = json['height'] ?? json['height_cm'];
    final weightVal = json['weight'] ?? json['weight_kg'];
    final casteVal = _stringish(json['caste'] ?? json['caste_id']);
    final subCasteVal = _stringish(json['sub_caste'] ?? json['sub_caste_id']);
    final stateVal = _stringish(json['state'] ?? json['state_id']);
    final districtVal = _stringish(json['district'] ?? json['district_id']);
    // Partner preference may arrive as map or list
    dynamic partnerPrefDyn =
        json['partner_preference'] ?? json['partner_preferences'];
    if (partnerPrefDyn is List && partnerPrefDyn.isNotEmpty) {
      partnerPrefDyn = partnerPrefDyn.first;
    }

    // Text partner preferences, only accept if it's a string, otherwise ignore
    String? partnerPrefsText;
    if (json['partner_preferences'] is String) {
      partnerPrefsText = json['partner_preferences'];
    } else if (json['partnerPrefs'] is String) {
      partnerPrefsText = json['partnerPrefs'];
    }

    // Ensure contact/family are maps (unwrap first element if list)
    Map<String, dynamic> _ensureMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
        return Map<String, dynamic>.from(v.first as Map<String, dynamic>);
      }
      return <String, dynamic>{};
    }

    List<String> _stringList(dynamic v) {
      if (v == null) return [];
      if (v is List)
        return v
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      if (v is String && v.isNotEmpty) return [v];
      return [];
    }

    return MatrimonialUser(
      id: _stringish(json['id']) ?? '',
      profileId: _stringish(json['profile_id']) ?? '',
      name: _stringish(json['name']) ?? '',
      email: _stringish(json['email']) ?? '',
      profileImageUrl: _stringish(json['profile_image_url']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      gender: _stringish(json['gender']) ?? '',
      dateOfBirth: _parseDate(json['date_of_birth']),
      religion: _stringish(json['religion']) ?? '',
      caste: casteVal ?? '',
      subCaste: subCasteVal ?? '',
      state: stateVal ?? '',
      district: districtVal ?? '',
      city: _stringish(json['city']) ?? '',
      education: _stringish(json['education']) ?? '',
      occupation: _stringish(json['occupation']) ?? '',
      workingLocation: _stringish(json['working_location']) ?? '',
      annualIncome: json['annual_income'] is num
          ? (json['annual_income'] as num).toDouble()
          : null,
      maritalStatus: _stringish(json['marital_status']) ?? '',
      aboutMe: _stringish(json['about_me']),
      familyDetails: _stringish(json['family_details']),
      partnerPreferences: partnerPrefsText,
      hobbies: _stringList(json['hobbies']),
      languages: _stringList(json['languages']),
      height: (heightVal is num) ? heightVal.toDouble() : null,
      weight: (weightVal is num) ? weightVal.toDouble() : null,
      physicalDisability: _stringish(json['physical_disability']),
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      isProfileComplete: json['is_profile_complete'] ?? false,
      photoUrls: _stringList(json['photo_urls']),
      contactInfo: ContactInfo.fromJson(_ensureMap(json['contact_info'])),
      familyInfo: FamilyInfo.fromJson(_ensureMap(json['family_info'])),
      partnerPreference: PartnerPreference.fromJson(
        partnerPrefDyn is Map<String, dynamic> ? partnerPrefDyn : {},
      ),
      shortlistedProfiles: _stringList(json['shortlisted_profiles']),
      blockedProfiles: _stringList(json['blocked_profiles']),
      viewedProfiles: _stringList(json['viewed_profiles']),
      viewedByProfiles: _stringList(json['viewed_by_profiles']),
      totalViews: json['total_views'] ?? 0,
      totalInterests: json['total_interests'] ?? 0,
      lastActiveAt: json['last_active_at'] != null
          ? _parseDate(json['last_active_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'email': email,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'religion': religion,
      'caste': caste,
      'sub_caste': subCaste,
      'state': state,
      'district': district,
      'city': city,
      'education': education,
      'occupation': occupation,
      'working_location': workingLocation,
      'annual_income': annualIncome,
      'marital_status': maritalStatus,
      'about_me': aboutMe,
      'family_details': familyDetails,
      'partner_preferences': partnerPreferences,
      'hobbies': hobbies,
      'languages': languages,
      'height': height,
      'weight': weight,
      'physical_disability': physicalDisability,
      'is_active': isActive,
      'is_verified': isVerified,
      'is_profile_complete': isProfileComplete,
      'photo_urls': photoUrls,
      'contact_info': contactInfo.toJson(),
      'family_info': familyInfo.toJson(),
      'partner_preference': partnerPreference.toJson(),
      'shortlisted_profiles': shortlistedProfiles,
      'blocked_profiles': blockedProfiles,
      'viewed_profiles': viewedProfiles,
      'viewed_by_profiles': viewedByProfiles,
      'total_views': totalViews,
      'total_interests': totalInterests,
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }
}

class ContactInfo {
  final String? phoneNumber;
  final String? alternatePhoneNumber;
  final String? whatsappNumber;
  final String? currentAddress;
  final String? permanentAddress;
  final bool showPhone;
  final bool showAddress;

  ContactInfo({
    this.phoneNumber,
    this.alternatePhoneNumber,
    this.whatsappNumber,
    this.currentAddress,
    this.permanentAddress,
    this.showPhone = false,
    this.showAddress = false,
  });

  ContactInfo copyWith({
    String? phoneNumber,
    String? alternatePhoneNumber,
    String? whatsappNumber,
    String? currentAddress,
    String? permanentAddress,
    bool? showPhone,
    bool? showAddress,
  }) {
    return ContactInfo(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      alternatePhoneNumber: alternatePhoneNumber ?? this.alternatePhoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      showPhone: showPhone ?? this.showPhone,
      showAddress: showAddress ?? this.showAddress,
    );
  }

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phoneNumber: json['phone_number'],
      alternatePhoneNumber: json['alternate_phone_number'],
      whatsappNumber: json['whatsapp_number'],
      currentAddress: json['current_address'],
      permanentAddress: json['permanent_address'],
      showPhone: json['show_phone'] ?? false,
      showAddress: json['show_address'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'alternate_phone_number': alternatePhoneNumber,
      'whatsapp_number': whatsappNumber,
      'current_address': currentAddress,
      'permanent_address': permanentAddress,
      'show_phone': showPhone,
      'show_address': showAddress,
    };
  }
}

class FamilyInfo {
  final String? fatherName;
  final String? fatherOccupation;
  final String? motherName;
  final String? motherOccupation;
  final int? numberOfBrothers;
  final int? numberOfSisters;
  final String? familyType; // Nuclear, Joint
  final String? familyValues; // Traditional, Modern, Moderate
  final String? familyStatus; // Middle Class, Upper Middle Class, Rich
  final String? familyDetails;

  FamilyInfo({
    this.fatherName,
    this.fatherOccupation,
    this.motherName,
    this.motherOccupation,
    this.numberOfBrothers,
    this.numberOfSisters,
    this.familyType,
    this.familyValues,
    this.familyStatus,
    this.familyDetails,
  });

  FamilyInfo copyWith({
    String? fatherName,
    String? fatherOccupation,
    String? motherName,
    String? motherOccupation,
    int? numberOfBrothers,
    int? numberOfSisters,
    String? familyType,
    String? familyValues,
    String? familyStatus,
    String? familyDetails,
  }) {
    return FamilyInfo(
      fatherName: fatherName ?? this.fatherName,
      fatherOccupation: fatherOccupation ?? this.fatherOccupation,
      motherName: motherName ?? this.motherName,
      motherOccupation: motherOccupation ?? this.motherOccupation,
      numberOfBrothers: numberOfBrothers ?? this.numberOfBrothers,
      numberOfSisters: numberOfSisters ?? this.numberOfSisters,
      familyType: familyType ?? this.familyType,
      familyValues: familyValues ?? this.familyValues,
      familyStatus: familyStatus ?? this.familyStatus,
      familyDetails: familyDetails ?? this.familyDetails,
    );
  }

  factory FamilyInfo.fromJson(Map<String, dynamic> json) {
    return FamilyInfo(
      fatherName: json['father_name'],
      fatherOccupation: json['father_occupation'],
      motherName: json['mother_name'],
      motherOccupation: json['mother_occupation'],
      numberOfBrothers: json['number_of_brothers'],
      numberOfSisters: json['number_of_sisters'],
      familyType: json['family_type'],
      familyValues: json['family_values'],
      familyStatus: json['family_status'],
      familyDetails: json['family_details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'father_name': fatherName,
      'father_occupation': fatherOccupation,
      'mother_name': motherName,
      'mother_occupation': motherOccupation,
      'number_of_brothers': numberOfBrothers,
      'number_of_sisters': numberOfSisters,
      'family_type': familyType,
      'family_values': familyValues,
      'family_status': familyStatus,
      'family_details': familyDetails,
    };
  }
}

class PartnerPreference {
  final int? minAge;
  final int? maxAge;
  final double? minHeight;
  final double? maxHeight;
  final List<String> preferredStates;
  final List<String> preferredDistricts;
  final List<String> preferredCastes;
  final List<String> preferredEducation;
  final List<String> preferredOccupation;
  final double? minIncome;
  final double? maxIncome;
  final List<String> preferredMaritalStatus;
  final String? otherPreferences;

  PartnerPreference({
    this.minAge,
    this.maxAge,
    this.minHeight,
    this.maxHeight,
    this.preferredStates = const [],
    this.preferredDistricts = const [],
    this.preferredCastes = const [],
    this.preferredEducation = const [],
    this.preferredOccupation = const [],
    this.minIncome,
    this.maxIncome,
    this.preferredMaritalStatus = const [],
    this.otherPreferences,
  });

  PartnerPreference copyWith({
    int? minAge,
    int? maxAge,
    double? minHeight,
    double? maxHeight,
    List<String>? preferredStates,
    List<String>? preferredDistricts,
    List<String>? preferredCastes,
    List<String>? preferredEducation,
    List<String>? preferredOccupation,
    double? minIncome,
    double? maxIncome,
    List<String>? preferredMaritalStatus,
    String? otherPreferences,
  }) {
    return PartnerPreference(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      preferredStates: preferredStates ?? this.preferredStates,
      preferredDistricts: preferredDistricts ?? this.preferredDistricts,
      preferredCastes: preferredCastes ?? this.preferredCastes,
      preferredEducation: preferredEducation ?? this.preferredEducation,
      preferredOccupation: preferredOccupation ?? this.preferredOccupation,
      minIncome: minIncome ?? this.minIncome,
      maxIncome: maxIncome ?? this.maxIncome,
      preferredMaritalStatus:
          preferredMaritalStatus ?? this.preferredMaritalStatus,
      otherPreferences: otherPreferences ?? this.otherPreferences,
    );
  }

  factory PartnerPreference.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return PartnerPreference(
      minAge: _toInt(json['min_age']),
      maxAge: _toInt(json['max_age']),
      minHeight: _toDouble(json['min_height'] ?? json['min_height_cm']),
      maxHeight: _toDouble(json['max_height'] ?? json['max_height_cm']),
      preferredStates: List<String>.from(json['preferred_states'] ?? []),
      preferredDistricts: List<String>.from(json['preferred_districts'] ?? []),
      preferredCastes: List<String>.from(json['preferred_castes'] ?? []),
      preferredEducation: List<String>.from(json['preferred_education'] ?? []),
      preferredOccupation: List<String>.from(
        json['preferred_occupation'] ?? [],
      ),
      minIncome: _toDouble(json['min_income']),
      maxIncome: _toDouble(json['max_income']),
      preferredMaritalStatus: List<String>.from(
        json['preferred_marital_status'] ?? [],
      ),
      otherPreferences: json['other_preferences'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_age': minAge,
      'max_age': maxAge,
      'min_height': minHeight,
      'max_height': maxHeight,
      'preferred_states': preferredStates,
      'preferred_districts': preferredDistricts,
      'preferred_castes': preferredCastes,
      'preferred_education': preferredEducation,
      'preferred_occupation': preferredOccupation,
      'min_income': minIncome,
      'max_income': maxIncome,
      'preferred_marital_status': preferredMaritalStatus,
      'other_preferences': otherPreferences,
    };
  }
}

class ProfileInteraction {
  final String id;
  final String fromProfileId;
  final String toProfileId;
  final InteractionType type;
  final DateTime createdAt;
  final String? message;
  final InteractionStatus status;

  ProfileInteraction({
    required this.id,
    required this.fromProfileId,
    required this.toProfileId,
    required this.type,
    required this.createdAt,
    this.message,
    required this.status,
  });

  factory ProfileInteraction.fromJson(Map<String, dynamic> json) {
    return ProfileInteraction(
      id: json['id'],
      fromProfileId: json['from_profile_id'],
      toProfileId: json['to_profile_id'],
      type: InteractionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      message: json['message'],
      status: InteractionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_profile_id': fromProfileId,
      'to_profile_id': toProfileId,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'message': message,
      'status': status.toString().split('.').last,
    };
  }
}

enum InteractionType { interest, shortlist, contact, message, block }

enum InteractionStatus { pending, accepted, rejected, cancelled }
