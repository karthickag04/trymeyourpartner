# TryMeYourPartner - Matrimonial Platform for Indian Diaspora

A comprehensive matrimonial platform built with Flutter and Supabase, specifically designed for the Indian diaspora worldwide. The platform focuses on connecting individuals based on caste, state, and district preferences, with Tamil Nadu as the initial target region.

## Features

### 🎯 Core Features
- **Caste-based Matching**: Users see profiles from their own caste community
- **Location-based Preferences**: State and district-wise categorization for better matches
- **Gender-specific Display**: Males see female profiles and vice versa
- **Priority Matching**: District matches get highest priority, followed by state, then others

### 👥 User Management
- **Complete Profile Creation**: Detailed matrimonial profiles with personal, family, and preference information
- **Authentication**: Secure email-based registration with verification
- **Profile Verification**: Verified profile badges for trusted users
- **Photo Gallery**: Multiple profile photos support

### 💝 Matching System
- **Smart Matching**: Algorithm prioritizes same caste, district, and state preferences
- **Interest Management**: Send/receive interests with status tracking
- **Shortlisting**: Save interesting profiles for later review
- **Profile Views**: Track who viewed your profile and view history

### 🔍 Search & Discovery
- **Advanced Filters**: Search by age, height, education, occupation, location, and more
- **Browse Profiles**: Explore compatible matches with detailed information
- **Match Recommendations**: Get personalized suggestions based on preferences

### 📱 User Experience
- **Cross-Platform**: Available on Android, iOS, and Web
- **Dark Theme**: Modern, matrimonial-focused UI design
- **Responsive**: Optimized for all screen sizes
- **Real-time Updates**: Live data synchronization

## Technical Architecture

### Frontend
- **Framework**: Flutter 3.8.1+
- **State Management**: Provider Pattern
- **UI Components**: Custom matrimonial-focused widgets
- **Navigation**: Bottom navigation with dedicated sections

### Backend
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth with email verification
- **Storage**: Supabase Storage for profile images
- **API**: RESTful APIs with Row Level Security (RLS)

### Database Structure
- **States & Districts**: Complete Indian geography data
- **Castes**: Religion-wise caste categorization
- **User Profiles**: Comprehensive matrimonial profiles
- **Interactions**: Interests, shortlists, views, and blocks
- **Preferences**: Detailed partner preference system

## Project Structure

```
lib/
├── models/             # Data models
│   ├── matrimonial_user.dart    # Main user profile model
│   ├── location_data.dart       # States/districts model
│   └── user.dart               # Basic user model
├── screens/            # Application screens
│   ├── home_screen.dart        # Dashboard with recommendations
│   ├── search_screen.dart      # Profile search and filters
│   ├── matches_screen.dart     # Matches, interests, shortlists
│   ├── profile_screen.dart     # User profile management
│   ├── profile_detail_screen.dart # Detailed profile view
│   └── auth_screen.dart        # Authentication
├── widgets/            # Reusable UI components
│   ├── profile_card.dart       # Profile display card
│   └── ...                    # Other widgets
├── providers/          # State management
│   ├── matrimonial_provider.dart  # Main matrimonial logic
│   ├── auth_provider.dart         # Authentication state
│   └── ...                       # Other providers
├── services/           # Business logic & API calls
│   ├── matrimonial_service.dart   # Matrimonial operations
│   └── ...                       # Other services
├── utils/              # Constants and utilities
│   ├── constants.dart             # App constants & data
│   └── theme.dart                # UI theme
└── main.dart           # Application entry point
```

## Setup Instructions

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK 2.19.0 or higher
- Android Studio / VS Code
- Supabase account

### 1. Clone the Repository
```bash
git clone <repository-url>
cd trymeyourpartner
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Supabase Setup

#### Create Supabase Project
1. Go to [Supabase](https://supabase.com) and create a new project
2. Note down your project URL and anon key

#### Configure Database
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Run the `matrimonial_database_schema.sql` file to create all tables and initial data

#### Update Configuration
1. Create `lib/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Table names
  static const String usersTable = 'matrimonial_profiles';
  static const String statesTable = 'states';
  static const String districtsTable = 'districts';
  static const String castesTable = 'castes';
  static const String interactionsTable = 'profile_interactions';
  static const String viewsTable = 'profile_views';
  static const String shortlistsTable = 'shortlisted_profiles';
}
```

#### Configure Authentication
1. In Supabase dashboard, go to Authentication → Settings
2. Enable email confirmations
3. Set Site URL to your app's URL
4. Configure redirect URLs for your platform

### 4. Run the Application
```bash
flutter run
```

### 5. Build for Production

#### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## Current Implementation Status

### ✅ Completed Features
- Project structure and navigation
- Authentication system with Supabase
- Database schema with Tamil Nadu data
- User profile models and data structures
- Basic UI components and screens
- Provider pattern implementation

### 🚧 In Development
- Complete profile creation flow
- Search and filtering functionality
- Matching algorithm implementation
- Interest and shortlist management
- Photo upload and gallery
- Notification system

### 📋 Planned Features
- Chat/messaging system
- Video calling integration
- Premium subscription tiers
- Advanced matching algorithms
- Mobile app deployment
- Multi-language support

## Database Schema

The platform uses a comprehensive database schema designed for matrimonial matching:

### Core Tables
- **states**: Indian states data
- **districts**: District data linked to states
- **castes**: Religion-wise caste categorization
- **matrimonial_profiles**: Complete user profiles
- **contact_info**: Contact details with privacy controls
- **family_info**: Family background information
- **partner_preferences**: Detailed partner criteria

### Interaction Tables
- **profile_interactions**: Interests, messages, blocks
- **profile_views**: Profile viewing history
- **shortlisted_profiles**: User shortlists
- **blocked_profiles**: Blocked users

### Key Features
- Row Level Security (RLS) for data protection
- Automatic profile ID generation
- View counting and interest tracking
- Comprehensive indexing for performance

## Matching Algorithm

The platform implements a sophisticated matching system:

1. **Primary Filter**: Same caste community
2. **Priority Order**: 
   - Same district (highest priority)
   - Same state (medium priority)
   - Other locations (lowest priority)
3. **Gender Compatibility**: Opposite gender profiles only
4. **Preference Matching**: Age, height, education, occupation filters
5. **Profile Completeness**: Verified and complete profiles get higher visibility

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and queries:
- Create an issue in the repository
- Contact the development team

## Acknowledgments

- Flutter team for the amazing framework
- Supabase team for the backend infrastructure
- Indian government data sources for location information
- Community contributors and testers

---

**TryMeYourPartner** - Connecting hearts across the Indian diaspora worldwide! 💕
