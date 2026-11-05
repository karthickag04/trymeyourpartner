// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TryMeYourPartner';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonDone => 'Done';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonView => 'View';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonNotSpecified => 'Not specified';

  @override
  String get commonSomethingWentWrong =>
      'Something went wrong. Please try again.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageChooseTooltip => 'Change language';

  @override
  String get authTagline => 'Find your life partner with trust';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Please enter your email';

  @override
  String get authEmailInvalid => 'Please enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String authPasswordTooShort(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authFullNameRequired => 'Please enter your full name';

  @override
  String get authOrContinueWith => 'Or continue with';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authWelcomeBack => 'Welcome back!';

  @override
  String get authAccountCreated =>
      'Account created successfully! Welcome to TryMeYourPartner!';

  @override
  String get authCheckEmailTitle => 'Check your email';

  @override
  String authVerificationSent(String email) {
    return 'We\'ve sent a verification link to $email';
  }

  @override
  String get authVerificationInstruction =>
      'Please open the link in your email to verify your account.';

  @override
  String get authSignedInWithGoogle => 'Signed in with Google!';

  @override
  String get authGoogleUnavailableTitle => 'Google sign-in unavailable';

  @override
  String get authGoogleUnavailableBody =>
      'Google sign-in is not set up for this app yet. Please sign in with your email instead.';

  @override
  String get authEnterEmailFirst => 'Please enter your email first';

  @override
  String get authPasswordResetSent => 'Password reset email sent!';

  @override
  String get authErrorInvalidCredentials =>
      'The email or password is incorrect.';

  @override
  String get authErrorAlreadyRegistered =>
      'An account with this email already exists. Please sign in.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Please verify your email before signing in.';

  @override
  String get authErrorSignUpFailed =>
      'We couldn\'t create your account. Please try again.';

  @override
  String get authErrorGoogleFailed =>
      'Google sign-in didn\'t work. Please try again.';

  @override
  String get authErrorNetwork =>
      'Can\'t reach the server. Check your internet connection and try again.';

  @override
  String get splashTagline => 'Where families find the right match';

  @override
  String get splashLoading => 'Loading your experience...';

  @override
  String get navHome => 'Home';

  @override
  String get navMatches => 'Matches';

  @override
  String get navSearch => 'Search';

  @override
  String get navInterests => 'Interests';

  @override
  String get navProfile => 'Profile';

  @override
  String get toastNewMessage => 'New message';

  @override
  String get toastInterestReceived => 'You received a new interest';

  @override
  String get toastInterestAccepted => 'Your interest was accepted';

  @override
  String get toastInterestRejected => 'Your interest was declined';

  @override
  String get toastNewNotification => 'New notification';

  @override
  String interestsBadgeLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new interests',
      one: '1 new interest',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: 'An hour ago',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: 'A week ago',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: 'A month ago',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesShort(int count) {
    return '${count}m';
  }

  @override
  String timeHoursShort(int count) {
    return '${count}h';
  }

  @override
  String timeDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceOffline => 'Offline';

  @override
  String get profileNotAvailable => 'This profile is not available.';

  @override
  String get contactLimitReached =>
      'You have used all contact views in your plan.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsMarkRead => 'Mark read';

  @override
  String get notificationNewMessage => 'New message';

  @override
  String get notificationNewInterest => 'New interest';

  @override
  String get notificationInterestAccepted => 'Interest accepted';

  @override
  String get notificationGeneric => 'Notification';

  @override
  String get contactRequestsTitle => 'Contact requests';

  @override
  String get contactRequestsReceived => 'Received';

  @override
  String get contactRequestsSent => 'Sent';

  @override
  String get contactRequestsEmpty => 'No requests yet';

  @override
  String contactRequestStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get contactStatusPending => 'Pending';

  @override
  String get contactStatusAccepted => 'Accepted';

  @override
  String get contactStatusDeclined => 'Declined';

  @override
  String get contactStatusCancelled => 'Cancelled';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionDecline => 'Decline';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesSignInRequired => 'Please sign in to see your messages';

  @override
  String get messagesLoadFailed => 'We couldn\'t load your messages.';

  @override
  String get messagesEmpty => 'No messages yet';

  @override
  String get profileNotActive => 'Profile not active';

  @override
  String get profileNotActiveNow => 'This profile is not active at the moment';

  @override
  String unreadCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
    );
    return '$_temp0';
  }

  @override
  String countOverflow(int max) {
    return '$max+';
  }

  @override
  String get chatLoadFailed => 'We couldn\'t load this conversation.';

  @override
  String get chatSendFailed => 'Your message wasn\'t sent. Please try again.';

  @override
  String get chatMyProfileInactive =>
      'Your profile is deactivated. Reactivate it to send messages.';

  @override
  String get chatOtherProfileInactive =>
      'This profile is not active at the moment. You can read earlier messages but can\'t send new ones.';

  @override
  String get chatTyping => 'Typing…';

  @override
  String get chatSuggestPrompt => 'Suggest a conversation starter';

  @override
  String get chatMessageHint => 'Type a message';

  @override
  String get chatSend => 'Send';

  @override
  String chatLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get chatStarterPassion =>
      'What\'s something you\'re passionate about outside of work?';

  @override
  String get chatStarterWeekend =>
      'Weekend plans: relaxing at home or going out?';

  @override
  String get chatStarterSmallJoy =>
      'What\'s a small joy that made your day recently?';

  @override
  String get chatTickSent => 'Sent';

  @override
  String get chatTickDelivered => 'Delivered';

  @override
  String get chatTickRead => 'Read';

  @override
  String get notificationsTabAccepted => 'Accepted';

  @override
  String get notificationsTabInterests => 'Interests';

  @override
  String get notificationsTabContactRequests => 'Contact requests';

  @override
  String newItemsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String get acceptedEmptyTitle => 'No accepted connections yet';

  @override
  String get acceptedEmptySubtitle =>
      'When interests are accepted, they will appear here.';

  @override
  String get interestsEmptyTitle => 'No new interests';

  @override
  String get interestsEmptySubtitle =>
      'Interests you receive will appear here.';

  @override
  String get contactReceivedHeader => 'Received (approve or decline)';

  @override
  String contactFrom(Object name) {
    return 'From: $name';
  }

  @override
  String contactRequestedAt(Object date) {
    return 'Requested on $date';
  }

  @override
  String get actionApprove => 'Approve';

  @override
  String get contactNoReceived => 'No requests received.';

  @override
  String get contactSentHeader => 'Sent (awaiting reply)';

  @override
  String contactTo(Object name) {
    return 'To: $name';
  }

  @override
  String get contactNoSent => 'No requests sent.';

  @override
  String profileAgePlace(int age, String place) {
    return '$age yrs · $place';
  }

  @override
  String ageYears(int age) {
    return '$age yrs';
  }

  @override
  String get interestsTitle => 'Interests';

  @override
  String get interestsTabReceived => 'Received';

  @override
  String get interestsTabSent => 'Sent';

  @override
  String get interestsLoadingReceived => 'Loading interests you received…';

  @override
  String get interestsLoadingSent => 'Loading interests you sent…';

  @override
  String get interestsReceivedEmptyTitle => 'No interests received yet';

  @override
  String get interestsReceivedEmptySubtitle =>
      'When someone shows interest in your profile, they will appear here.';

  @override
  String get interestsSentEmptyTitle => 'No interests sent yet';

  @override
  String get interestsSentEmptySubtitle =>
      'Browse profiles and send interests to start connecting.';

  @override
  String profileAgeCity(int age, String city) {
    return '$age years • $city';
  }

  @override
  String get profileNoAbout => 'No information provided';

  @override
  String interestAccepted(Object name) {
    return 'You accepted $name\'s interest';
  }

  @override
  String get interestAcceptFailed =>
      'We couldn\'t accept this interest. Please try again.';

  @override
  String interestDeclined(Object name) {
    return 'You declined $name\'s interest';
  }

  @override
  String get interestDeclineFailed =>
      'We couldn\'t decline this interest. Please try again.';

  @override
  String ageYearsLong(int age) {
    return '$age years';
  }

  @override
  String get actionShortlist => 'Shortlist';

  @override
  String get actionShortlisted => 'Shortlisted';

  @override
  String get actionReject => 'Decline';

  @override
  String get actionSendInterest => 'Send interest';

  @override
  String get actionInterestSent => 'Interest sent';

  @override
  String get badgeVerified => 'Verified profile';

  @override
  String get badgeShortlisted => 'In your shortlist';

  @override
  String placeDistrictState(Object district, Object state) {
    return '$district, $state';
  }

  @override
  String profileAgeHeight(int age, String height) {
    return '$age years, $height';
  }

  @override
  String get whyMatchedTooltip => 'Why this match';

  @override
  String get actionInterest => 'Interest';

  @override
  String get actionAddToShortlist => 'Add to shortlist';

  @override
  String get actionRemoveFromShortlist => 'Remove from shortlist';

  @override
  String whyMatchNearby(Object district) {
    return 'You live near $district';
  }

  @override
  String whyMatchEducation(Object education) {
    return 'Similar education: $education';
  }

  @override
  String whyMatchCaste(Object caste) {
    return 'Caste preference matched: $caste';
  }

  @override
  String whyMatchLanguages(Object languages) {
    return 'Languages in common: $languages';
  }

  @override
  String get whyMatchGeneral => 'Good compatibility based on your preferences';
}
