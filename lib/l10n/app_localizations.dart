import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// Brand name; not translated.
  ///
  /// In en, this message translates to:
  /// **'TryMeYourPartner'**
  String get appName;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get commonNotSpecified;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonSomethingWentWrong;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageChooseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageChooseTooltip;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Find your life partner with trust'**
  String get authTagline;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String authPasswordTooShort(int min);

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullNameLabel;

  /// No description provided for @authFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get authFullNameRequired;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get authWelcomeBack;

  /// No description provided for @authAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Welcome to TryMeYourPartner!'**
  String get authAccountCreated;

  /// No description provided for @authCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authCheckEmailTitle;

  /// No description provided for @authVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to {email}'**
  String authVerificationSent(String email);

  /// No description provided for @authVerificationInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please open the link in your email to verify your account.'**
  String get authVerificationInstruction;

  /// No description provided for @authSignedInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google!'**
  String get authSignedInWithGoogle;

  /// No description provided for @authGoogleUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in unavailable'**
  String get authGoogleUnavailableTitle;

  /// No description provided for @authGoogleUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not set up for this app yet. Please sign in with your email instead.'**
  String get authGoogleUnavailableBody;

  /// No description provided for @authEnterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email first'**
  String get authEnterEmailFirst;

  /// No description provided for @authPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent!'**
  String get authPasswordResetSent;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Please sign in.'**
  String get authErrorAlreadyRegistered;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before signing in.'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorSignUpFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create your account. Please try again.'**
  String get authErrorSignUpFailed;

  /// No description provided for @authErrorGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in didn\'t work. Please try again.'**
  String get authErrorGoogleFailed;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your internet connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Where families find the right match'**
  String get splashTagline;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your experience...'**
  String get splashLoading;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get navInterests;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @toastNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get toastNewMessage;

  /// No description provided for @toastInterestReceived.
  ///
  /// In en, this message translates to:
  /// **'You received a new interest'**
  String get toastInterestReceived;

  /// No description provided for @toastInterestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your interest was accepted'**
  String get toastInterestAccepted;

  /// No description provided for @toastInterestRejected.
  ///
  /// In en, this message translates to:
  /// **'Your interest was declined'**
  String get toastInterestRejected;

  /// No description provided for @toastNewNotification.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get toastNewNotification;

  /// No description provided for @interestsBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new interest} other{{count} new interests}}'**
  String interestsBadgeLabel(int count);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{An hour ago} other{{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A week ago} other{{count} weeks ago}}'**
  String timeWeeksAgo(int count);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A month ago} other{{count} months ago}}'**
  String timeMonthsAgo(int count);

  /// No description provided for @timeMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String timeMinutesShort(int count);

  /// No description provided for @timeHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String timeHoursShort(int count);

  /// No description provided for @timeDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String timeDaysShort(int count);

  /// No description provided for @presenceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get presenceOnline;

  /// No description provided for @presenceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get presenceOffline;

  /// No description provided for @profileNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This profile is not available.'**
  String get profileNotAvailable;

  /// No description provided for @contactLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have used all contact views in your plan.'**
  String get contactLimitReached;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get notificationsMarkRead;

  /// No description provided for @notificationNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notificationNewMessage;

  /// No description provided for @notificationNewInterest.
  ///
  /// In en, this message translates to:
  /// **'New interest'**
  String get notificationNewInterest;

  /// No description provided for @notificationInterestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Interest accepted'**
  String get notificationInterestAccepted;

  /// No description provided for @notificationGeneric.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationGeneric;

  /// No description provided for @contactRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact requests'**
  String get contactRequestsTitle;

  /// No description provided for @contactRequestsReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get contactRequestsReceived;

  /// No description provided for @contactRequestsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get contactRequestsSent;

  /// No description provided for @contactRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get contactRequestsEmpty;

  /// No description provided for @contactRequestStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String contactRequestStatus(String status);

  /// No description provided for @contactStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get contactStatusPending;

  /// No description provided for @contactStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get contactStatusAccepted;

  /// No description provided for @contactStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get contactStatusDeclined;

  /// No description provided for @contactStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get contactStatusCancelled;

  /// No description provided for @actionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// No description provided for @actionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get actionDecline;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @messagesSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to see your messages'**
  String get messagesSignInRequired;

  /// No description provided for @messagesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your messages.'**
  String get messagesLoadFailed;

  /// No description provided for @messagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get messagesEmpty;

  /// No description provided for @profileNotActive.
  ///
  /// In en, this message translates to:
  /// **'Profile not active'**
  String get profileNotActive;

  /// No description provided for @profileNotActiveNow.
  ///
  /// In en, this message translates to:
  /// **'This profile is not active at the moment'**
  String get profileNotActiveNow;

  /// No description provided for @unreadCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread message} other{{count} unread messages}}'**
  String unreadCountLabel(int count);

  /// No description provided for @countOverflow.
  ///
  /// In en, this message translates to:
  /// **'{max}+'**
  String countOverflow(int max);

  /// No description provided for @chatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this conversation.'**
  String get chatLoadFailed;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Your message wasn\'t sent. Please try again.'**
  String get chatSendFailed;

  /// No description provided for @chatMyProfileInactive.
  ///
  /// In en, this message translates to:
  /// **'Your profile is deactivated. Reactivate it to send messages.'**
  String get chatMyProfileInactive;

  /// No description provided for @chatOtherProfileInactive.
  ///
  /// In en, this message translates to:
  /// **'This profile is not active at the moment. You can read earlier messages but can\'t send new ones.'**
  String get chatOtherProfileInactive;

  /// No description provided for @chatTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing…'**
  String get chatTyping;

  /// No description provided for @chatSuggestPrompt.
  ///
  /// In en, this message translates to:
  /// **'Suggest a conversation starter'**
  String get chatSuggestPrompt;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get chatMessageHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String chatLastSeen(String time);

  /// No description provided for @chatStarterPassion.
  ///
  /// In en, this message translates to:
  /// **'What\'s something you\'re passionate about outside of work?'**
  String get chatStarterPassion;

  /// No description provided for @chatStarterWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend plans: relaxing at home or going out?'**
  String get chatStarterWeekend;

  /// No description provided for @chatStarterSmallJoy.
  ///
  /// In en, this message translates to:
  /// **'What\'s a small joy that made your day recently?'**
  String get chatStarterSmallJoy;

  /// No description provided for @chatTickSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatTickSent;

  /// No description provided for @chatTickDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get chatTickDelivered;

  /// No description provided for @chatTickRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatTickRead;

  /// No description provided for @notificationsTabAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get notificationsTabAccepted;

  /// No description provided for @notificationsTabInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get notificationsTabInterests;

  /// No description provided for @notificationsTabContactRequests.
  ///
  /// In en, this message translates to:
  /// **'Contact requests'**
  String get notificationsTabContactRequests;

  /// No description provided for @newItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new} other{{count} new}}'**
  String newItemsLabel(int count);

  /// No description provided for @acceptedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No accepted connections yet'**
  String get acceptedEmptyTitle;

  /// No description provided for @acceptedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When interests are accepted, they will appear here.'**
  String get acceptedEmptySubtitle;

  /// No description provided for @interestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No new interests'**
  String get interestsEmptyTitle;

  /// No description provided for @interestsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interests you receive will appear here.'**
  String get interestsEmptySubtitle;

  /// No description provided for @contactReceivedHeader.
  ///
  /// In en, this message translates to:
  /// **'Received (approve or decline)'**
  String get contactReceivedHeader;

  /// No description provided for @contactFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {name}'**
  String contactFrom(Object name);

  /// No description provided for @contactRequestedAt.
  ///
  /// In en, this message translates to:
  /// **'Requested on {date}'**
  String contactRequestedAt(Object date);

  /// No description provided for @actionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get actionApprove;

  /// No description provided for @contactNoReceived.
  ///
  /// In en, this message translates to:
  /// **'No requests received.'**
  String get contactNoReceived;

  /// No description provided for @contactSentHeader.
  ///
  /// In en, this message translates to:
  /// **'Sent (awaiting reply)'**
  String get contactSentHeader;

  /// No description provided for @contactTo.
  ///
  /// In en, this message translates to:
  /// **'To: {name}'**
  String contactTo(Object name);

  /// No description provided for @contactNoSent.
  ///
  /// In en, this message translates to:
  /// **'No requests sent.'**
  String get contactNoSent;

  /// No description provided for @profileAgePlace.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs · {place}'**
  String profileAgePlace(int age, String place);

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs'**
  String ageYears(int age);

  /// No description provided for @interestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interestsTitle;

  /// No description provided for @interestsTabReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get interestsTabReceived;

  /// No description provided for @interestsTabSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get interestsTabSent;

  /// No description provided for @interestsLoadingReceived.
  ///
  /// In en, this message translates to:
  /// **'Loading interests you received…'**
  String get interestsLoadingReceived;

  /// No description provided for @interestsLoadingSent.
  ///
  /// In en, this message translates to:
  /// **'Loading interests you sent…'**
  String get interestsLoadingSent;

  /// No description provided for @interestsReceivedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No interests received yet'**
  String get interestsReceivedEmptyTitle;

  /// No description provided for @interestsReceivedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone shows interest in your profile, they will appear here.'**
  String get interestsReceivedEmptySubtitle;

  /// No description provided for @interestsSentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No interests sent yet'**
  String get interestsSentEmptyTitle;

  /// No description provided for @interestsSentEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse profiles and send interests to start connecting.'**
  String get interestsSentEmptySubtitle;

  /// No description provided for @profileAgeCity.
  ///
  /// In en, this message translates to:
  /// **'{age} years • {city}'**
  String profileAgeCity(int age, String city);

  /// No description provided for @profileNoAbout.
  ///
  /// In en, this message translates to:
  /// **'No information provided'**
  String get profileNoAbout;

  /// No description provided for @interestAccepted.
  ///
  /// In en, this message translates to:
  /// **'You accepted {name}\'s interest'**
  String interestAccepted(Object name);

  /// No description provided for @interestAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t accept this interest. Please try again.'**
  String get interestAcceptFailed;

  /// No description provided for @interestDeclined.
  ///
  /// In en, this message translates to:
  /// **'You declined {name}\'s interest'**
  String interestDeclined(Object name);

  /// No description provided for @interestDeclineFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t decline this interest. Please try again.'**
  String get interestDeclineFailed;

  /// No description provided for @ageYearsLong.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String ageYearsLong(int age);

  /// No description provided for @actionShortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get actionShortlist;

  /// No description provided for @actionShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get actionShortlisted;

  /// No description provided for @actionReject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get actionReject;

  /// No description provided for @actionSendInterest.
  ///
  /// In en, this message translates to:
  /// **'Send interest'**
  String get actionSendInterest;

  /// No description provided for @actionInterestSent.
  ///
  /// In en, this message translates to:
  /// **'Interest sent'**
  String get actionInterestSent;

  /// No description provided for @badgeVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified profile'**
  String get badgeVerified;

  /// No description provided for @badgeShortlisted.
  ///
  /// In en, this message translates to:
  /// **'In your shortlist'**
  String get badgeShortlisted;

  /// No description provided for @placeDistrictState.
  ///
  /// In en, this message translates to:
  /// **'{district}, {state}'**
  String placeDistrictState(Object district, Object state);

  /// No description provided for @profileAgeHeight.
  ///
  /// In en, this message translates to:
  /// **'{age} years, {height}'**
  String profileAgeHeight(int age, String height);

  /// No description provided for @whyMatchedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Why this match'**
  String get whyMatchedTooltip;

  /// No description provided for @actionInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get actionInterest;

  /// No description provided for @actionAddToShortlist.
  ///
  /// In en, this message translates to:
  /// **'Add to shortlist'**
  String get actionAddToShortlist;

  /// No description provided for @actionRemoveFromShortlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from shortlist'**
  String get actionRemoveFromShortlist;

  /// No description provided for @whyMatchNearby.
  ///
  /// In en, this message translates to:
  /// **'You live near {district}'**
  String whyMatchNearby(Object district);

  /// No description provided for @whyMatchEducation.
  ///
  /// In en, this message translates to:
  /// **'Similar education: {education}'**
  String whyMatchEducation(Object education);

  /// No description provided for @whyMatchCaste.
  ///
  /// In en, this message translates to:
  /// **'Caste preference matched: {caste}'**
  String whyMatchCaste(Object caste);

  /// No description provided for @whyMatchLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages in common: {languages}'**
  String whyMatchLanguages(Object languages);

  /// No description provided for @whyMatchGeneral.
  ///
  /// In en, this message translates to:
  /// **'Good compatibility based on your preferences'**
  String get whyMatchGeneral;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
