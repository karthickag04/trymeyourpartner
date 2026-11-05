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

  @override
  String get maintenanceTitle => 'Under maintenance';

  @override
  String get maintenanceDefaultMessage =>
      'We are making improvements. Please check back soon.';

  @override
  String get helpTitle => 'Help & Support';

  @override
  String get helpIntro =>
      'Need help with your account, a profile or a payment? Contact our support team.';

  @override
  String get helpNoContacts => 'Support contacts are not available right now.';

  @override
  String get helpEmail => 'Email';

  @override
  String get helpPhone => 'Phone';

  @override
  String get helpWhatsapp => 'WhatsApp';

  @override
  String get helpCopy => 'Copy';

  @override
  String helpCopied(Object label) {
    return '$label copied';
  }

  @override
  String get contactRevealUnavailable =>
      'Contact reveal is not available right now.';

  @override
  String get sectionBasicInfo => 'Basic information';

  @override
  String get sectionAboutMe => 'About me';

  @override
  String get sectionFamilyInfo => 'Family information';

  @override
  String get sectionPartnerPreferences => 'Partner preferences';

  @override
  String get sectionSimilarProfiles => 'Similar profiles';

  @override
  String get fieldReligion => 'Religion';

  @override
  String get fieldCaste => 'Caste';

  @override
  String get fieldSubCaste => 'Sub-caste';

  @override
  String get fieldEducation => 'Education';

  @override
  String get fieldOccupation => 'Occupation';

  @override
  String get fieldWorkingLocation => 'Working location';

  @override
  String get fieldAnnualIncome => 'Annual income';

  @override
  String get fieldHeight => 'Height';

  @override
  String get fieldWeight => 'Weight';

  @override
  String get fieldMaritalStatus => 'Marital status';

  @override
  String get fieldLanguages => 'Languages';

  @override
  String get fieldHobbies => 'Hobbies';

  @override
  String get fieldFatherName => 'Father\'s name';

  @override
  String get fieldFatherOccupation => 'Father\'s occupation';

  @override
  String get fieldMotherName => 'Mother\'s name';

  @override
  String get fieldMotherOccupation => 'Mother\'s occupation';

  @override
  String get fieldBrothers => 'Brothers';

  @override
  String get fieldSisters => 'Sisters';

  @override
  String get fieldFamilyType => 'Family type';

  @override
  String get fieldFamilyValues => 'Family values';

  @override
  String get fieldFamilyStatus => 'Family status';

  @override
  String get fieldPreferredAge => 'Preferred age';

  @override
  String get fieldPreferredHeight => 'Preferred height';

  @override
  String get fieldPreferredStates => 'Preferred states';

  @override
  String get fieldPreferredCastes => 'Preferred castes';

  @override
  String get fieldPreferredEducation => 'Preferred education';

  @override
  String get fieldPreferredOccupation => 'Preferred occupation';

  @override
  String get fieldPreferredIncome => 'Preferred income';

  @override
  String get fieldOtherPreferences => 'Other preferences';

  @override
  String get actionMessage => 'Message';

  @override
  String get actionRevealContact => 'Reveal / request contact';

  @override
  String get pleaseSignIn => 'Please sign in first';

  @override
  String get blockedNoReveal =>
      'You can\'t view contact details of a blocked profile';

  @override
  String get contactRequestPending => 'Contact request pending';

  @override
  String get signInToMessage => 'Please sign in to send a message';

  @override
  String get profileInactiveTitle => 'Profile inactive';

  @override
  String get profileInactiveReactivatePrompt =>
      'Your profile is deactivated. Reactivate it now to send messages?';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get actionReactivate => 'Reactivate';

  @override
  String get profileReactivated => 'Profile reactivated';

  @override
  String get profileReactivateFailed =>
      'We couldn\'t reactivate your profile. Please try again.';

  @override
  String get messagingDisabledInactive =>
      'This profile is not active. Messaging is turned off for now.';

  @override
  String get messagingDisabledBlocked =>
      'Messaging is turned off for blocked profiles';

  @override
  String get contactRequestSent => 'Contact request sent';

  @override
  String get contactRequestFailed =>
      'We couldn\'t send the request. Please try again.';

  @override
  String get acceptContactTitle => 'Accept contact request?';

  @override
  String acceptContactBody(Object name) {
    return 'Share contact details with $name?';
  }

  @override
  String get commonNo => 'No';

  @override
  String get contactRequestAccepted => 'Contact request accepted';

  @override
  String get contactAcceptFailed =>
      'We couldn\'t accept the request. Please try again.';

  @override
  String interestSentTo(Object name) {
    return 'Interest sent to $name';
  }

  @override
  String get interestSendFailed =>
      'We couldn\'t send your interest. Please try again.';

  @override
  String get shortlistRemoved => 'Removed from shortlist';

  @override
  String get shortlistAdded => 'Added to shortlist';

  @override
  String get shortlistFailed =>
      'We couldn\'t update your shortlist. Please try again.';

  @override
  String get contactDetailsTitle => 'Contact details';

  @override
  String get contactNoPhone => 'This member has not added a phone number yet.';

  @override
  String contactPhone(Object number) {
    return 'Phone: $number';
  }

  @override
  String contactWhatsapp(Object number) {
    return 'WhatsApp: $number';
  }

  @override
  String get contactLimitUpgrade =>
      'You\'ve reached your plan\'s contact limit. Upgrade your plan to see more.';

  @override
  String get contactRevealFailed =>
      'We couldn\'t show the contact details. Please try again.';

  @override
  String messageTo(Object name) {
    return 'Message $name';
  }

  @override
  String get messageHintLong => 'Type your message…';

  @override
  String get messageSent => 'Message sent';

  @override
  String get messageSendFailed =>
      'We couldn\'t send your message. Please try again.';

  @override
  String get blockProfileAction => 'Block profile';

  @override
  String get reportProfileAction => 'Report profile';

  @override
  String get blockProfileTitle => 'Block profile?';

  @override
  String blockProfileBody(Object name) {
    return 'You will no longer see $name, and they won\'t be able to contact you.';
  }

  @override
  String get profileBlocked => 'Profile blocked';

  @override
  String get blockFailed =>
      'We couldn\'t block this profile. Please try again.';

  @override
  String get actionBlock => 'Block';

  @override
  String get reportProfileTitle => 'Report profile';

  @override
  String get reportReason => 'Reason';

  @override
  String get reportDetails => 'Details (optional)';

  @override
  String get reportSubmitted =>
      'Report submitted. Thank you for helping keep the community safe.';

  @override
  String get reportFailed =>
      'We couldn\'t submit your report. Please try again.';

  @override
  String get actionSubmit => 'Submit';

  @override
  String get similarEmpty => 'No similar profiles found yet.';

  @override
  String get moreOptions => 'More options';

  @override
  String get previousPhoto => 'Previous photo';

  @override
  String get nextPhoto => 'Next photo';

  @override
  String photoCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String ageYearsOld(int age) {
    return '$age years old';
  }

  @override
  String incomeLpa(String amount) {
    return '₹$amount LPA';
  }

  @override
  String weightKg(String weight) {
    return '$weight kg';
  }

  @override
  String ageRange(int min, int max) {
    return '$min - $max years';
  }

  @override
  String heightRangeCm(String min, String max) {
    return '$min - $max cm';
  }

  @override
  String incomeRangeLpa(String min, String max) {
    return '₹$min - $max LPA';
  }

  @override
  String get noLimit => 'No limit';

  @override
  String ageCityShort(int age, String city) {
    return '$age • $city';
  }

  @override
  String get homeSubtitle => 'Try Me For Your Partner Selection';

  @override
  String get statMatches => 'Matches';

  @override
  String get statShortlisted => 'Shortlisted';

  @override
  String get statViewedYou => 'Viewed you';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get homeTopPicks => 'Top picks for you';

  @override
  String get homeYourMatches => 'Your matches';

  @override
  String get homeViewedYou => 'Viewed you';

  @override
  String get homeNewThisWeek => 'New this week';

  @override
  String get homeViewedByYou => 'Viewed by you';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeEmptyTopPicks =>
      'No top picks yet. Highly compatible profiles will appear here.';

  @override
  String get homeEmptyMatches =>
      'No matches yet. Update your preferences or try searching.';

  @override
  String get homeEmptyViewedYou => 'No one has viewed your profile yet.';

  @override
  String get homeEmptyNewThisWeek => 'No new profiles in the last 7 days.';

  @override
  String get homeEmptyViewedByYou => 'Start viewing profiles to see them here.';

  @override
  String get homeCompleteProfileTitle => 'Complete your profile';

  @override
  String homeCompleteProfileProgress(int percent) {
    return '$percent% complete · Get better matches with full details';
  }

  @override
  String get homeCompleteAction => 'Complete';

  @override
  String get homeDeactivatedTitle => 'Your profile is deactivated';

  @override
  String get homeDeactivatedBody =>
      'Reactivate your profile to send and receive messages and appear in searches.';

  @override
  String statLabel(String label, int count) {
    return '$label: $count';
  }

  @override
  String get matchesTabMatches => 'Matches';

  @override
  String get matchesTabTopPicks => 'Top picks';

  @override
  String get matchesTabInterests => 'Interests';

  @override
  String get matchesTabShortlistedByYou => 'Shortlisted by you';

  @override
  String get matchesTabShortlistedYou => 'Shortlisted you';

  @override
  String get matchesTabViewed => 'Viewed';

  @override
  String get matchesTabViewedYou => 'Viewed you';

  @override
  String get matchesTabAccepted => 'Accepted';

  @override
  String get matchesChooseList => 'Choose a list';

  @override
  String get matchesPreviousList => 'Previous list';

  @override
  String get matchesNextList => 'Next list';

  @override
  String get signInRequiredTitle => 'Sign in required';

  @override
  String get signInRequiredBody =>
      'Sign in to find your match and connect with compatible profiles';

  @override
  String get matchesEmptyTitle => 'No matches yet';

  @override
  String get matchesEmptyBody => 'Complete your profile to get better matches';

  @override
  String get actionCompleteProfile => 'Complete profile';

  @override
  String get interestsNoneReceivedTitle => 'No interests received';

  @override
  String get interestsNoneReceivedBody =>
      'Your profile will receive interests from compatible matches';

  @override
  String get actionImproveProfile => 'Improve profile';

  @override
  String get topPicksEmptyTitle => 'No top picks yet';

  @override
  String get topPicksEmptyBody =>
      'Highly compatible profiles will appear here once matches are available';

  @override
  String get actionRefreshMatches => 'Refresh matches';

  @override
  String get shortlistEmptyTitle => 'No shortlisted profiles';

  @override
  String get shortlistEmptyBody =>
      'Browse profiles and shortlist the ones you like';

  @override
  String get actionBrowseProfiles => 'Browse profiles';

  @override
  String get shortlistedYouEmptyTitle => 'No one has shortlisted you yet';

  @override
  String get shortlistedYouEmptyBody =>
      'As more people discover your profile, you\'ll see them here';

  @override
  String get viewedEmptyTitle => 'No profile views';

  @override
  String get viewedEmptyBody => 'Start viewing profiles to see them here';

  @override
  String get viewedYouEmptyTitle => 'No profile views yet';

  @override
  String get viewedYouEmptyBody =>
      'People who view your profile will appear here';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get acceptedNoneTitle => 'No accepted connections';

  @override
  String get acceptedNoneBody => 'Accepted interests will appear here';

  @override
  String get matchesLoading => 'Loading matches…';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorLoadMatches =>
      'We couldn\'t load your matches. Check your connection and try again.';

  @override
  String interestAcceptedFrom(Object name) {
    return 'You accepted $name\'s interest';
  }

  @override
  String interestRejectedFrom(Object name) {
    return 'You declined $name\'s interest';
  }

  @override
  String get restartToSignIn => 'Please restart the app to sign in.';

  @override
  String get religionHindu => 'Hindu';

  @override
  String get religionMuslim => 'Muslim';

  @override
  String get religionChristian => 'Christian';

  @override
  String get religionSikh => 'Sikh';

  @override
  String get religionJain => 'Jain';

  @override
  String get religionBuddhist => 'Buddhist';

  @override
  String get optionOther => 'Other';

  @override
  String get maritalNeverMarried => 'Never married';

  @override
  String get maritalDivorced => 'Divorced';

  @override
  String get maritalWidowed => 'Widowed';

  @override
  String get maritalSeparated => 'Separated';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get createdBySelf => 'Self';

  @override
  String get createdBySibling => 'Sibling';

  @override
  String get createdByParents => 'Parents';

  @override
  String get createdByGuardian => 'Guardian';

  @override
  String get workBusiness => 'Business';

  @override
  String get workSalaried => 'Salaried';

  @override
  String get workNotWorking => 'Currently not working';

  @override
  String get registrationProfileCreated => 'Profile created';

  @override
  String get registrationSaveFailed =>
      'We couldn\'t save your details. Please try again.';

  @override
  String get registrationTitle => 'Complete registration';

  @override
  String get registrationEmailFromLogin => 'Email (from sign-in)';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get validationNameRequired => 'Please enter your name';

  @override
  String get fieldGender => 'Gender';

  @override
  String get validationSelectGender => 'Please select a gender';

  @override
  String get fieldDateOfBirth => 'Date of birth';

  @override
  String get validationSelectDob => 'Please select your date of birth';

  @override
  String get fieldPhone => 'Phone number';

  @override
  String get validationPhone => 'Please enter a valid phone number';

  @override
  String get fieldWhatsapp => 'WhatsApp number';

  @override
  String get validationWhatsapp => 'Please enter a valid WhatsApp number';

  @override
  String get fieldProfileCreatedBy => 'Profile created by';

  @override
  String get validationSelectOne => 'Please choose one';

  @override
  String get fieldWorkStatus => 'Work status';

  @override
  String get fieldOccupationCategory => 'Occupation category';

  @override
  String get fieldQualification => 'Qualification';

  @override
  String get fieldDiscipline => 'Discipline / field';

  @override
  String get actionAdd => 'Add';

  @override
  String get fieldCity => 'City';

  @override
  String get validationReligion => 'Please select a religion';

  @override
  String get validationCaste => 'Please select a caste';

  @override
  String get fieldSubCasteOptional => 'Sub-caste (optional)';

  @override
  String get fieldState => 'State';

  @override
  String get validationState => 'Please select a state';

  @override
  String get fieldDistrict => 'District';

  @override
  String get validationDistrict => 'Please select a district';

  @override
  String get actionSaveAndContinue => 'Save and continue';

  @override
  String get registrationLanguageHint =>
      'Choose the language you are most comfortable with';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLoading => 'Loading profile…';

  @override
  String get profileSignInBody =>
      'Sign in to see your profile, favourites and personalised recommendations';

  @override
  String planLabel(Object plan) {
    return 'Plan: $plan';
  }

  @override
  String get planFree => 'Free';

  @override
  String get planGold => 'Gold';

  @override
  String get planPlatinum => 'Platinum';

  @override
  String get upgradeComingSoon => 'Plan upgrades are not available yet.';

  @override
  String get actionUpgrade => 'Upgrade';

  @override
  String get emailVerificationTitle => 'Email verification required';

  @override
  String get emailVerificationBody =>
      'Please open the verification link in your email to finish setting up your account.';

  @override
  String get actionResend => 'Resend';

  @override
  String get changePhoto => 'Change profile photo';

  @override
  String memberSince(Object date) {
    return 'Member since $date';
  }

  @override
  String get actionEditProfile => 'Edit profile';

  @override
  String get actionManagePhotos => 'Manage photos';

  @override
  String get statProfile => 'Profile';

  @override
  String get statComplete => 'Complete';

  @override
  String get statIncomplete => 'Incomplete';

  @override
  String get quickActionsTitle => 'Quick actions';

  @override
  String get quickFavorites => 'My favourites';

  @override
  String get quickFavoritesSub => 'View your interests';

  @override
  String get quickMatchesSub => 'See your matches';

  @override
  String get quickCompletion => 'Profile completion';

  @override
  String get quickCompletionSub => 'Complete your profile';

  @override
  String get quickRefresh => 'Refresh data';

  @override
  String get quickRefreshSub => 'Reload your profile and suggestions';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSub => 'Manage notification preferences';

  @override
  String get settingsPrivacy => 'Privacy & security';

  @override
  String get settingsPrivacySub => 'Account security settings';

  @override
  String get settingsHelpSub => 'Get help and contact us';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutSub => 'App version and info';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get verificationEmailSent =>
      'Verification email sent. Please check your inbox.';

  @override
  String get verificationEmailFailed =>
      'We couldn\'t send the verification email. Please try again.';

  @override
  String get photoTake => 'Take photo';

  @override
  String get photoGallery => 'Choose from gallery';

  @override
  String get photoAdd => 'Add photo';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String get photoPrimary => 'Primary';

  @override
  String get photoMakePrimary => 'Make primary';

  @override
  String get accountActions => 'Account actions';

  @override
  String get actionReactivateProfile => 'Reactivate profile';

  @override
  String get actionDeactivateProfile => 'Deactivate profile';

  @override
  String get actionDeleteProfile => 'Delete profile';

  @override
  String get profileNotLoaded =>
      'Your profile hasn\'t loaded yet. Please try again.';

  @override
  String get deactivateBody =>
      'Deactivating hides your profile from searches and turns off incoming messages. You can reactivate it any time by editing your profile.';

  @override
  String get actionDeactivate => 'Deactivate';

  @override
  String get profileDeactivated => 'Profile deactivated';

  @override
  String get profileDeactivateFailed =>
      'We couldn\'t deactivate your profile. Please try again.';

  @override
  String get deleteBody =>
      'Deleting your profile permanently removes your profile records. A minimal archive is kept so support can restore it if needed. This cannot be undone.';

  @override
  String get actionDelete => 'Delete';

  @override
  String get profileDeleted => 'Profile deleted. Signing you out…';

  @override
  String get profileDeleteFailed =>
      'We couldn\'t delete your profile. Please try again.';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get signingOut => 'Signing out…';

  @override
  String get interestsShownHere => 'Your interests are in the Interests tab.';

  @override
  String get matchesInTab => 'Your matches are in the Matches tab.';

  @override
  String get notificationSettingsComingSoon =>
      'Notification settings are not available yet.';

  @override
  String get securitySettingsComingSoon =>
      'Security settings are not available yet.';

  @override
  String get aboutComingSoon => 'The About page is not available yet.';

  @override
  String get profileStatusActive => 'Your profile is active';

  @override
  String get profileStatusDeactivated => 'Your profile is deactivated';

  @override
  String get profileStatusMissing =>
      'No profile found. Create your profile to get matches.';

  @override
  String get noProfileTitle => 'No profile found';

  @override
  String get noProfileBody =>
      'We couldn\'t find a profile linked to your account. You can still browse, but to get personalised matches, please create your profile.';

  @override
  String get createProfileFailed =>
      'We couldn\'t create your profile. Please try again.';

  @override
  String get actionCreateProfile => 'Create my profile';

  @override
  String get profileRestored => 'Profile restored from archive.';

  @override
  String get noArchivedProfile => 'No archived profile found to restore.';

  @override
  String get restoreFailed =>
      'We couldn\'t restore your profile. Please try again.';

  @override
  String get actionRestoreProfile => 'Restore my profile';

  @override
  String get diagnosticsPrinted => 'Diagnostics written to the console';

  @override
  String get actionPrintDiagnostics => 'Print diagnostics';

  @override
  String get myProfileTitle => 'My profile';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldAge => 'Age';

  @override
  String get fieldLocation => 'Location';

  @override
  String get actionEditMyProfile => 'Edit my profile';

  @override
  String get refreshSuccess => 'Profile data refreshed';

  @override
  String get refreshNotSignedIn => 'Couldn\'t refresh: you\'re not signed in';

  @override
  String get defaultUserName => 'Member';

  @override
  String get statInterests => 'Interests';

  @override
  String get searchTitle => 'Search profiles';

  @override
  String get savedSearchesTooltip => 'Saved searches';

  @override
  String get contactRequestsTooltip => 'Contact requests';

  @override
  String get actionResetFilters => 'Reset filters';

  @override
  String get searchTip =>
      'Tip: adjust the filters and tap Search to see results here.';

  @override
  String get searchLocationPrefs => 'Location preferences';

  @override
  String get searchBasicPrefs => 'Basic preferences';

  @override
  String get fieldSubCasteShort => 'Sub-caste';

  @override
  String get searchMoreEducations => 'More education options';

  @override
  String get searchMoreOccupations => 'More occupations';

  @override
  String get searchMoreCastes => 'More castes';

  @override
  String get searchRangePrefs => 'Range preferences';

  @override
  String get filterOnlineNow => 'Online now';

  @override
  String get filterRecentlyActive => 'Recently active';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortYoungerFirst => 'Younger first';

  @override
  String get sortOlderFirst => 'Older first';

  @override
  String get sortHigherIncome => 'Higher income';

  @override
  String get actionSaveSearch => 'Save this search';

  @override
  String get quickSearch => 'Quick search (no filters)';

  @override
  String get searchEmptyTitle => 'Search for profiles';

  @override
  String get searchEmptyBody =>
      'Use the filters above to find compatible matches';

  @override
  String get contactAvailable => 'Contact available';

  @override
  String get contactStateRequestSent => 'Request sent';

  @override
  String get contactStateRequestReceived => 'Request received';

  @override
  String get recentChip => 'Recent';

  @override
  String get joinedWithinTooltip => 'Joined within days';

  @override
  String get actionClearAll => 'Clear all';

  @override
  String get completeRegistrationFirst => 'Please complete registration first.';

  @override
  String get saveSearchTitle => 'Save this search';

  @override
  String get saveSearchHint => 'e.g. Chennai IT, 25-30, Hindu';

  @override
  String get savedSearchesTitle => 'Saved searches';

  @override
  String get savedSearchesEmpty => 'No saved searches yet.';

  @override
  String get deleteSavedSearchTitle => 'Delete saved search?';

  @override
  String get runSearch => 'Run search';

  @override
  String get fieldAbout => 'About';

  @override
  String get fieldLocationPlain => 'Location';

  @override
  String get searchLoading => 'Loading…';

  @override
  String rangeAge(int min, int max) {
    return 'Age: $min - $max years';
  }

  @override
  String rangeHeight(int min, int max) {
    return 'Height: $min - $max cm';
  }

  @override
  String heightCm(int value) {
    return '$value cm';
  }

  @override
  String rangeIncome(String min, String max) {
    return 'Income: ${min}L - ${max}L per year';
  }

  @override
  String incomeLakhShort(String value) {
    return '${value}L';
  }

  @override
  String profilesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles found',
      one: '1 profile found',
      zero: 'No profiles found',
    );
    return '$_temp0';
  }

  @override
  String profilesRecommended(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recommended profiles',
      one: '1 recommended profile',
    );
    return '$_temp0';
  }

  @override
  String chipLabelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String chipAgeRange(int min, int max) {
    return 'Age $min-$max';
  }

  @override
  String chipHeightRange(int min, int max) {
    return 'Height $min-$max cm';
  }

  @override
  String chipIncomeRange(String min, String max) {
    return 'Income $min-${max}L';
  }

  @override
  String joinedWithinDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Joined: last $days days',
      one: 'Joined: last day',
    );
    return '$_temp0';
  }

  @override
  String get searchFailed => 'Search didn\'t work. Please try again.';

  @override
  String get filtersLoadFailed =>
      'We couldn\'t load the filter options. Please try again.';

  @override
  String defaultSearchName(Object date) {
    return 'Search $date';
  }

  @override
  String savedSearchNamed(Object name) {
    return 'Saved search \"$name\"';
  }

  @override
  String get saveSearchFailed =>
      'We couldn\'t save this search. Please try again.';

  @override
  String deleteSavedSearchBody(Object name) {
    return '\"$name\" will be removed.';
  }

  @override
  String savedSearchAlertsOn(Object date) {
    return 'Alerts on • $date';
  }

  @override
  String savedSearchAlertsOff(Object date) {
    return 'Alerts off • $date';
  }

  @override
  String get toggleFailed =>
      'We couldn\'t change this setting. Please try again.';

  @override
  String heightCmOrUnknown(String value) {
    return '$value cm';
  }

  @override
  String get langTamil => 'Tamil';

  @override
  String get langEnglish => 'English';

  @override
  String get langTelugu => 'Telugu';

  @override
  String get langKannada => 'Kannada';

  @override
  String get langMalayalam => 'Malayalam';

  @override
  String get langHindi => 'Hindi';
}
