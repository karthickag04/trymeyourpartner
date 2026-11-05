// Data lists used by forms. Display labels come from lib/l10n.

export 'tokens.dart';

class AppConstants {
  static const String appName = 'TryMeYourPartner';
  static const String appVersion = '1.0.0';

  // API Constants
  static const String baseUrl = 'https://api.trymeyourpartner.com';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Matrimonial Categories
  static const List<String> religionCategories = [
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Jain',
    'Buddhist',
    'Other',
  ];

  // Popular states (focusing on Tamil Nadu initially)
  static const List<String> states = [
    'Tamil Nadu',
    'Karnataka',
    'Kerala',
    'Andhra Pradesh',
    'Telangana',
    'Maharashtra',
    'Gujarat',
    'West Bengal',
    'Delhi',
    'Punjab',
  ];

  // Tamil Nadu districts
  static const Map<String, List<String>> stateDistricts = {
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem',
      'Tirunelveli',
      'Thanjavur',
      'Vellore',
      'Erode',
      'Dindigul',
      'Cuddalore',
      'Kanchipuram',
      'Karur',
      'Nagapattinam',
      'Namakkal',
      'Perambalur',
      'Pudukkottai',
      'Ramanathapuram',
      'Sivaganga',
      'Tenkasi',
      'Theni',
      'Thiruvallur',
      'Thiruvannamalai',
      'Thiruvarur',
      'Thoothukudi',
      'Tiruppur',
      'Viluppuram',
      'Virudhunagar',
      'Nilgiris',
      'Krishnagiri',
      'Dharmapuri',
      'Tirupathur',
      'Ranipet',
      'Kallakurichi',
      'Chengalpattu',
      'Mayiladuthurai',
      'Ariyalur',
    ],
  };

  // Tamil Nadu castes (major ones)
  static const List<String> tamilNaduCastes = [
    'Brahmin',
    'Chettiar',
    'Mudaliar',
    'Pillai',
    'Reddy',
    'Naidu',
    'Thevar',
    'Gounder',
    'Vanniyar',
    'Yadav',
    'Naicker',
    'Other',
  ];

  // Education levels
  static const List<String> educationLevels = [
    'School',
    'Diploma',
    'Graduate',
    'Post Graduate',
    'Professional',
    'Doctorate',
  ];

  // Occupations
  static const List<String> occupations = [
    'Software Engineer',
    'Doctor',
    'Teacher',
    'Business Owner',
    'Government Employee',
    'Private Employee',
    'Engineer',
    'Lawyer',
    'Banking',
    'Other',
  ];

  // Marital status
  static const List<String> maritalStatuses = [
    'Never Married',
    'Divorced',
    'Widowed',
    'Separated',
  ];
}
