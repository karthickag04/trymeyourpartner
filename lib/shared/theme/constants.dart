import 'package:flutter/material.dart';

class AppColors {
  // Matrimonial Theme Colors - Red/Black/White Combination
  static const Color primary = Color(0xFFDC143C); // Crimson red primary
  static const Color secondary = Color(0xFFFFEBEE); // Very light red/white
  static const Color accent = Color(0xFFB71C1C); // Dark red accent
  static const Color background = Color(0xFFFFFFFF); // Pure white background
  static const Color surface = Color(0xFFFAFAFA); // Off-white surface
  static const Color textPrimary = Color(0xFF000000); // Pure black text
  static const Color textSecondary = Color(0xFF424242); // Dark gray text
  static const Color textTertiary = Color(0xFF757575); // Medium gray text
  static const Color error = Color(0xFFD32F2F); // Error red
  static const Color success = Color(0xFF388E3C); // Success green
  static const Color warning = Color(0xFFF57C00); // Warning orange
  static const Color info = Color(0xFF1976D2); // Info blue
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white cards
  static const Color divider = Color(0xFFE0E0E0); // Light gray divider
  static const Color transparent = Colors.transparent;

  // Additional matrimonial-specific colors
  static const Color heartRed = Color(0xFFE53E3E); // Heart/love red
  static const Color darkBackground = Color(
    0xFF212121,
  ); // Dark background for contrast
  static const Color lightRed = Color(0xFFFFCDD2); // Light red for highlights
}

class AppDimensions {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;

  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  static const double cardHeight = 200.0;
  static const double cardWidth = 140.0;
  static const double bannerHeight = 400.0;

  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 80.0;
}

class AppTextStyles {
  // Matrimonial-focused text styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );
}

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
