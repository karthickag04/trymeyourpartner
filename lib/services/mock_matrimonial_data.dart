// ignore_for_file: avoid_print
import '../models/matrimonial_user.dart';
import '../models/location_data.dart';
import '../utils/constants.dart';

class MockMatrimonialData {
  // Helper method to capitalize first letter
  static String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Mock current user profile
  static MatrimonialUser createMockCurrentUser(
    String authUserId,
    String email,
  ) {
    return MatrimonialUser(
      id: authUserId,
      profileId:
          'MP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      name: _capitalizeFirstLetter(email.split('@')[0]),
      email: email,
      profileImageUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
      gender: 'Male', // Default, can be changed in profile
      dateOfBirth: DateTime(1990, 1, 1),
      religion: 'Hindu',
      caste: 'Brahmin',
      subCaste: '',
      state: 'Tamil Nadu',
      district: 'Chennai',
      city: 'Chennai',
      education: 'Graduate',
      occupation: 'Software Engineer',
      workingLocation: 'Chennai',
      annualIncome: 800000.0,
      maritalStatus: 'Never Married',
      aboutMe:
          'Looking for a compatible life partner who shares similar values and interests.',
      familyDetails: null,
      partnerPreferences: null,
      hobbies: ['Reading', 'Music', 'Travel'],
      languages: ['Tamil', 'English'],
      height: 175.0,
      weight: 70.0,
      physicalDisability: null,
      isActive: true,
      isVerified: false,
      isProfileComplete: false,
      photoUrls: [],
      contactInfo: ContactInfo(
        phoneNumber: null,
        alternatePhoneNumber: null,
        whatsappNumber: null,
        currentAddress: null,
        permanentAddress: null,
        showPhone: false,
        showAddress: false,
      ),
      familyInfo: FamilyInfo(
        fatherName: null,
        fatherOccupation: null,
        motherName: null,
        motherOccupation: null,
        numberOfBrothers: 1,
        numberOfSisters: 0,
        familyType: 'Nuclear',
        familyValues: 'Traditional',
        familyStatus: 'Middle Class',
        familyDetails: null,
      ),
      partnerPreference: PartnerPreference(
        minAge: 22,
        maxAge: 30,
        minHeight: 155.0,
        maxHeight: 170.0,
        preferredStates: ['Tamil Nadu'],
        preferredDistricts: ['Chennai', 'Coimbatore', 'Madurai'],
        preferredCastes: ['Brahmin'],
        preferredEducation: ['Graduate', 'Post Graduate'],
        preferredOccupation: ['Software Engineer', 'Doctor', 'Teacher'],
        minIncome: 500000.0,
        maxIncome: null,
        preferredMaritalStatus: ['Never Married'],
        otherPreferences: 'Looking for a caring and understanding partner.',
      ),
      shortlistedProfiles: [],
      blockedProfiles: [],
      viewedProfiles: [],
      viewedByProfiles: [],
      totalViews: 12,
      totalInterests: 3,
      lastActiveAt: DateTime.now(),
    );
  }

  // Mock profiles for matching
  static List<MatrimonialUser> createMockProfiles() {
    final profiles = <MatrimonialUser>[];

    // Female profiles for male users
    final femaleProfiles = [
      {
        'name': 'Priya Sharma',
        'age': 25,
        'education': 'Post Graduate',
        'occupation': 'Software Engineer',
        'city': 'Chennai',
        'district': 'Chennai',
        'caste': 'Brahmin',
        'height': 162.0,
        'about':
            'Family oriented person with modern outlook. Love reading and classical music.',
      },
      {
        'name': 'Divya Mudaliar',
        'age': 27,
        'education': 'Graduate',
        'occupation': 'Teacher',
        'city': 'Coimbatore',
        'district': 'Coimbatore',
        'caste': 'Mudaliar',
        'height': 158.0,
        'about':
            'Simple and down to earth. Enjoy cooking and spending time with family.',
      },
      {
        'name': 'Kavitha Pillai',
        'age': 24,
        'education': 'Professional',
        'occupation': 'Doctor',
        'city': 'Madurai',
        'district': 'Madurai',
        'caste': 'Pillai',
        'height': 165.0,
        'about':
            'Dedicated healthcare professional. Looking for a supportive life partner.',
      },
      {
        'name': 'Meera Reddy',
        'age': 26,
        'education': 'Post Graduate',
        'occupation': 'Banking',
        'city': 'Trichy',
        'district': 'Tiruchirappalli',
        'caste': 'Reddy',
        'height': 160.0,
        'about':
            'Career focused yet family oriented. Love traveling and exploring new places.',
      },
      {
        'name': 'Anjali Naidu',
        'age': 23,
        'education': 'Graduate',
        'occupation': 'Private Employee',
        'city': 'Salem',
        'district': 'Salem',
        'caste': 'Naidu',
        'height': 157.0,
        'about':
            'Creative person with artistic interests. Value family traditions and culture.',
      },
      {
        'name': 'Deepika Gounder',
        'age': 28,
        'education': 'Graduate',
        'occupation': 'Business Owner',
        'city': 'Erode',
        'district': 'Erode',
        'caste': 'Gounder',
        'height': 163.0,
        'about':
            'Entrepreneur with strong family values. Enjoy outdoor activities and sports.',
      },
      {
        'name': 'Lakshmi Thevar',
        'age': 25,
        'education': 'Professional',
        'occupation': 'Engineer',
        'city': 'Dindigul',
        'district': 'Dindigul',
        'caste': 'Thevar',
        'height': 161.0,
        'about':
            'Technical professional with traditional values. Love music and dance.',
      },
      {
        'name': 'Radhika Vanniyar',
        'age': 24,
        'education': 'Graduate',
        'occupation': 'Government Employee',
        'city': 'Vellore',
        'district': 'Vellore',
        'caste': 'Vanniyar',
        'height': 159.0,
        'about':
            'Stable career with government job. Enjoy reading and gardening.',
      },
    ];

    // Male profiles for female users
    final maleProfiles = [
      {
        'name': 'Rajesh Kumar',
        'age': 28,
        'education': 'Post Graduate',
        'occupation': 'Software Engineer',
        'city': 'Chennai',
        'district': 'Chennai',
        'caste': 'Brahmin',
        'height': 175.0,
        'about':
            'Tech professional with strong family values. Enjoy cricket and movies.',
      },
      {
        'name': 'Arun Mudaliar',
        'age': 30,
        'education': 'Professional',
        'occupation': 'Doctor',
        'city': 'Coimbatore',
        'district': 'Coimbatore',
        'caste': 'Mudaliar',
        'height': 178.0,
        'about':
            'Medical professional dedicated to service. Love traveling and photography.',
      },
      {
        'name': 'Karthik Pillai',
        'age': 27,
        'education': 'Graduate',
        'occupation': 'Engineer',
        'city': 'Madurai',
        'district': 'Madurai',
        'caste': 'Pillai',
        'height': 172.0,
        'about':
            'Engineering professional with modern outlook. Enjoy music and sports.',
      },
      {
        'name': 'Suresh Reddy',
        'age': 29,
        'education': 'Post Graduate',
        'occupation': 'Business Owner',
        'city': 'Trichy',
        'district': 'Tiruchirappalli',
        'caste': 'Reddy',
        'height': 176.0,
        'about':
            'Successful businessman with traditional values. Love cooking and travel.',
      },
      {
        'name': 'Venkat Naidu',
        'age': 26,
        'education': 'Graduate',
        'occupation': 'Banking',
        'city': 'Salem',
        'district': 'Salem',
        'caste': 'Naidu',
        'height': 174.0,
        'about':
            'Banking professional with stable career. Enjoy reading and fitness.',
      },
      {
        'name': 'Murugan Gounder',
        'age': 31,
        'education': 'Graduate',
        'occupation': 'Government Employee',
        'city': 'Erode',
        'district': 'Erode',
        'caste': 'Gounder',
        'height': 170.0,
        'about':
            'Government employee with secure job. Family oriented with traditional values.',
      },
      {
        'name': 'Selvam Thevar',
        'age': 28,
        'education': 'Professional',
        'occupation': 'Lawyer',
        'city': 'Dindigul',
        'district': 'Dindigul',
        'caste': 'Thevar',
        'height': 173.0,
        'about':
            'Legal professional fighting for justice. Enjoy debates and social service.',
      },
      {
        'name': 'Kumar Vanniyar',
        'age': 27,
        'education': 'Graduate',
        'occupation': 'Teacher',
        'city': 'Vellore',
        'district': 'Vellore',
        'caste': 'Vanniyar',
        'height': 171.0,
        'about':
            'Educator passionate about teaching. Love books and classical music.',
      },
    ];

    // Create female profiles
    for (int i = 0; i < femaleProfiles.length; i++) {
      final profile = femaleProfiles[i];
      profiles.add(
        _createProfile(
          id: 'mock_female_$i',
          profileId: 'MP00${1000 + i}',
          gender: 'Female',
          profileData: profile,
        ),
      );
    }

    // Create male profiles
    for (int i = 0; i < maleProfiles.length; i++) {
      final profile = maleProfiles[i];
      profiles.add(
        _createProfile(
          id: 'mock_male_$i',
          profileId: 'MP00${2000 + i}',
          gender: 'Male',
          profileData: profile,
        ),
      );
    }

    return profiles;
  }

  static MatrimonialUser _createProfile({
    required String id,
    required String profileId,
    required String gender,
    required Map<String, dynamic> profileData,
  }) {
    final now = DateTime.now();
    final birthYear = now.year - (profileData['age'] as int);

    // Profile images based on gender and index
    final profileImages = gender == 'Female'
        ? [
            'https://images.unsplash.com/photo-1494790108755-2616b612b5bc?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=400&fit=crop&crop=face',
          ]
        : [
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1463453091185-61582044d556?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1557862921-37829c790f19?w=400&h=400&fit=crop&crop=face',
            'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&h=400&fit=crop&crop=face',
          ];

    final imageIndex = int.parse(id.split('_').last) % profileImages.length;

    return MatrimonialUser(
      id: id,
      profileId: profileId,
      name: profileData['name'],
      email:
          '${profileData['name'].toString().toLowerCase().replaceAll(' ', '.')}@example.com',
      profileImageUrl: profileImages[imageIndex],
      createdAt: now.subtract(Duration(days: (profileData['age'] as int) * 2)),
      updatedAt: now,
      gender: gender,
      dateOfBirth: DateTime(birthYear, 6, 15),
      religion: 'Hindu',
      caste: profileData['caste'],
      subCaste: '',
      state: 'Tamil Nadu',
      district: profileData['district'],
      city: profileData['city'],
      education: profileData['education'],
      occupation: profileData['occupation'],
      workingLocation: profileData['city'],
      annualIncome: _getRandomIncome(profileData['occupation']),
      maritalStatus: 'Never Married',
      aboutMe: profileData['about'],
      familyDetails: 'Close knit family with strong values and traditions.',
      partnerPreferences:
          'Looking for a life partner who shares similar values and goals.',
      hobbies: _getRandomHobbies(),
      languages: ['Tamil', 'English'],
      height: profileData['height'],
      weight: gender == 'Male' ? 75.0 : 55.0,
      physicalDisability: null,
      isActive: true,
      isVerified: (profileData['age'] as int) > 26,
      isProfileComplete: true,
      photoUrls: [],
      contactInfo: ContactInfo(
        phoneNumber: null,
        alternatePhoneNumber: null,
        whatsappNumber: null,
        currentAddress: null,
        permanentAddress: null,
        showPhone: false,
        showAddress: false,
      ),
      familyInfo: FamilyInfo(
        fatherName: null,
        fatherOccupation: null,
        motherName: null,
        motherOccupation: null,
        numberOfBrothers: 1,
        numberOfSisters: 1,
        familyType: 'Nuclear',
        familyValues: 'Traditional',
        familyStatus: 'Middle Class',
        familyDetails:
            'Well educated and cultured family with traditional values.',
      ),
      partnerPreference: PartnerPreference(
        minAge: gender == 'Male' ? 22 : 25,
        maxAge: gender == 'Male' ? 28 : 32,
        minHeight: gender == 'Male' ? 155.0 : 170.0,
        maxHeight: gender == 'Male' ? 165.0 : 180.0,
        preferredStates: ['Tamil Nadu'],
        preferredDistricts: [profileData['district']],
        preferredCastes: [profileData['caste']],
        preferredEducation: ['Graduate', 'Post Graduate'],
        preferredOccupation: [
          'Software Engineer',
          'Doctor',
          'Teacher',
          'Engineer',
        ],
        minIncome: gender == 'Male' ? null : 500000.0,
        maxIncome: null,
        preferredMaritalStatus: ['Never Married'],
        otherPreferences:
            'Looking for a caring and understanding partner with similar background.',
      ),
      shortlistedProfiles: [],
      blockedProfiles: [],
      viewedProfiles: [],
      viewedByProfiles: [],
      totalViews: (profileData['age'] as int) * 2,
      totalInterests: ((profileData['age'] as int) / 5).floor(),
      lastActiveAt: now.subtract(
        Duration(hours: (profileData['age'] as int) % 24),
      ),
    );
  }

  static double _getRandomIncome(String occupation) {
    final incomeMap = {
      'Software Engineer': 1200000.0,
      'Doctor': 1500000.0,
      'Teacher': 600000.0,
      'Engineer': 800000.0,
      'Banking': 900000.0,
      'Business Owner': 1800000.0,
      'Government Employee': 700000.0,
      'Lawyer': 1000000.0,
      'Private Employee': 500000.0,
    };
    return incomeMap[occupation] ?? 600000.0;
  }

  static List<String> _getRandomHobbies() {
    final allHobbies = [
      'Reading',
      'Music',
      'Travel',
      'Cooking',
      'Dancing',
      'Singing',
      'Photography',
      'Sports',
      'Gardening',
      'Movies',
      'Shopping',
      'Art',
    ];
    allHobbies.shuffle();
    return allHobbies.take(3).toList();
  }

  // Mock states and districts
  static List<LocationData> getMockStates() {
    return [
      LocationData(
        id: 'state_1',
        name: 'Tamil Nadu',
        type: 'state',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      LocationData(
        id: 'state_2',
        name: 'Karnataka',
        type: 'state',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      LocationData(
        id: 'state_3',
        name: 'Kerala',
        type: 'state',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  static List<LocationData> getMockDistricts(String stateId) {
    if (stateId == 'state_1') {
      // Tamil Nadu districts
      return AppConstants.stateDistricts['Tamil Nadu']!
          .asMap()
          .entries
          .map(
            (entry) => LocationData(
              id: 'district_tn_${entry.key}',
              name: entry.value,
              type: 'district',
              parentId: stateId,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
    }
    return [];
  }

  // Mock castes
  static List<CasteData> getMockCastes(String religion) {
    if (religion == 'Hindu') {
      return AppConstants.tamilNaduCastes
          .asMap()
          .entries
          .map(
            (entry) => CasteData(
              id: 'caste_${entry.key}',
              name: entry.value,
              religion: religion,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
    }
    return [];
  }

  // Get matches for a user (opposite gender, same caste)
  static List<MatrimonialUser> getMatchesForUser(MatrimonialUser currentUser) {
    final allProfiles = createMockProfiles();
    final oppositeGender = currentUser.gender == 'Male' ? 'Female' : 'Male';

    return allProfiles
        .where(
          (profile) =>
              profile.gender == oppositeGender &&
              profile.caste == currentUser.caste,
        )
        .toList();
  }

  // Get random interests (profiles that showed interest in current user)
  static List<MatrimonialUser> getReceivedInterests(
    MatrimonialUser currentUser,
  ) {
    final allProfiles = createMockProfiles();
    final oppositeGender = currentUser.gender == 'Male' ? 'Female' : 'Male';

    final interests = allProfiles
        .where((profile) => profile.gender == oppositeGender)
        .take(3)
        .toList();

    return interests;
  }

  // Simulate search results
  static List<MatrimonialUser> searchProfiles({
    required String currentUserId,
    String? currentUserGender,
    String? state,
    String? district,
    String? caste,
    int? minAge,
    int? maxAge,
    String? education,
    String? occupation,
    double? minHeight,
    double? maxHeight,
  }) {
    print('🔍 MockData.searchProfiles called with:');
    print('  currentUserId: $currentUserId');
    print('  currentUserGender: $currentUserGender');
    print('  state: $state, district: $district, caste: $caste');

    final allProfiles = createMockProfiles();
    print('🔍 Total mock profiles: ${allProfiles.length}');

    final oppositeGender = currentUserGender == 'Male' ? 'Female' : 'Male';
    print('🔍 Looking for gender: $oppositeGender');

    var results = allProfiles.where(
      (profile) =>
          profile.id != currentUserId && profile.gender == oppositeGender,
    );

    print('🔍 After gender filter: ${results.length}');

    if (state != null) {
      results = results.where((p) => p.state == state);
      print('🔍 After state filter ($state): ${results.length}');
    }
    if (district != null) {
      results = results.where((p) => p.district == district);
      print('🔍 After district filter ($district): ${results.length}');
    }
    if (caste != null) {
      results = results.where((p) => p.caste == caste);
      print('🔍 After caste filter ($caste): ${results.length}');
    }
    if (minAge != null) {
      results = results.where((p) => p.age >= minAge);
      print('🔍 After minAge filter ($minAge): ${results.length}');
    }
    if (maxAge != null) {
      results = results.where((p) => p.age <= maxAge);
      print('🔍 After maxAge filter ($maxAge): ${results.length}');
    }
    if (education != null) {
      results = results.where((p) => p.education == education);
      print('🔍 After education filter ($education): ${results.length}');
    }
    if (occupation != null) {
      results = results.where((p) => p.occupation == occupation);
      print('🔍 After occupation filter ($occupation): ${results.length}');
    }
    if (minHeight != null) {
      results = results.where((p) => (p.height ?? 0) >= minHeight);
      print('🔍 After minHeight filter ($minHeight): ${results.length}');
    }
    if (maxHeight != null) {
      results = results.where((p) => (p.height ?? 0) <= maxHeight);
      print('🔍 After maxHeight filter ($maxHeight): ${results.length}');
    }

    final finalResults = results.toList();
    print('🔍 Final search results: ${finalResults.length}');

    return finalResults;
  }
}
