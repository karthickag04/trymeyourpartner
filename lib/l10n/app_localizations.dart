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

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your profile. Your details are safe. Check your connection and try again.'**
  String get profileLoadFailed;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

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
  /// **'Find your life partner, the trusted way'**
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

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'We are making improvements. Please check back soon.'**
  String get maintenanceDefaultMessage;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Need help with your account, a profile or a payment? Contact our support team.'**
  String get helpIntro;

  /// No description provided for @helpNoContacts.
  ///
  /// In en, this message translates to:
  /// **'Support contacts are not available right now.'**
  String get helpNoContacts;

  /// No description provided for @helpEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get helpEmail;

  /// No description provided for @helpPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get helpPhone;

  /// No description provided for @helpWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get helpWhatsapp;

  /// No description provided for @helpCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get helpCopy;

  /// No description provided for @helpCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String helpCopied(Object label);

  /// No description provided for @contactRevealUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Contact reveal is not available right now.'**
  String get contactRevealUnavailable;

  /// No description provided for @sectionBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get sectionBasicInfo;

  /// No description provided for @sectionAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get sectionAboutMe;

  /// No description provided for @sectionFamilyInfo.
  ///
  /// In en, this message translates to:
  /// **'Family information'**
  String get sectionFamilyInfo;

  /// No description provided for @sectionPartnerPreferences.
  ///
  /// In en, this message translates to:
  /// **'Partner preferences'**
  String get sectionPartnerPreferences;

  /// No description provided for @sectionSimilarProfiles.
  ///
  /// In en, this message translates to:
  /// **'Similar profiles'**
  String get sectionSimilarProfiles;

  /// No description provided for @fieldReligion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get fieldReligion;

  /// No description provided for @fieldCaste.
  ///
  /// In en, this message translates to:
  /// **'Caste'**
  String get fieldCaste;

  /// No description provided for @fieldSubCaste.
  ///
  /// In en, this message translates to:
  /// **'Sub-caste'**
  String get fieldSubCaste;

  /// No description provided for @fieldEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get fieldEducation;

  /// No description provided for @fieldOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get fieldOccupation;

  /// No description provided for @fieldWorkingLocation.
  ///
  /// In en, this message translates to:
  /// **'Working location'**
  String get fieldWorkingLocation;

  /// No description provided for @fieldAnnualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual income'**
  String get fieldAnnualIncome;

  /// No description provided for @fieldHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get fieldHeight;

  /// No description provided for @fieldWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get fieldWeight;

  /// No description provided for @fieldMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get fieldMaritalStatus;

  /// No description provided for @fieldLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get fieldLanguages;

  /// No description provided for @fieldHobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get fieldHobbies;

  /// No description provided for @fieldFatherName.
  ///
  /// In en, this message translates to:
  /// **'Father\'s name'**
  String get fieldFatherName;

  /// No description provided for @fieldFatherOccupation.
  ///
  /// In en, this message translates to:
  /// **'Father\'s occupation'**
  String get fieldFatherOccupation;

  /// No description provided for @fieldMotherName.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s name'**
  String get fieldMotherName;

  /// No description provided for @fieldMotherOccupation.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s occupation'**
  String get fieldMotherOccupation;

  /// No description provided for @fieldBrothers.
  ///
  /// In en, this message translates to:
  /// **'Brothers'**
  String get fieldBrothers;

  /// No description provided for @fieldSisters.
  ///
  /// In en, this message translates to:
  /// **'Sisters'**
  String get fieldSisters;

  /// No description provided for @fieldFamilyType.
  ///
  /// In en, this message translates to:
  /// **'Family type'**
  String get fieldFamilyType;

  /// No description provided for @fieldFamilyValues.
  ///
  /// In en, this message translates to:
  /// **'Family values'**
  String get fieldFamilyValues;

  /// No description provided for @fieldFamilyStatus.
  ///
  /// In en, this message translates to:
  /// **'Family status'**
  String get fieldFamilyStatus;

  /// No description provided for @fieldPreferredAge.
  ///
  /// In en, this message translates to:
  /// **'Preferred age'**
  String get fieldPreferredAge;

  /// No description provided for @fieldPreferredHeight.
  ///
  /// In en, this message translates to:
  /// **'Preferred height'**
  String get fieldPreferredHeight;

  /// No description provided for @fieldPreferredStates.
  ///
  /// In en, this message translates to:
  /// **'Preferred states'**
  String get fieldPreferredStates;

  /// No description provided for @fieldPreferredCastes.
  ///
  /// In en, this message translates to:
  /// **'Preferred castes'**
  String get fieldPreferredCastes;

  /// No description provided for @fieldPreferredEducation.
  ///
  /// In en, this message translates to:
  /// **'Preferred education'**
  String get fieldPreferredEducation;

  /// No description provided for @fieldPreferredOccupation.
  ///
  /// In en, this message translates to:
  /// **'Preferred occupation'**
  String get fieldPreferredOccupation;

  /// No description provided for @fieldPreferredIncome.
  ///
  /// In en, this message translates to:
  /// **'Preferred income'**
  String get fieldPreferredIncome;

  /// No description provided for @fieldOtherPreferences.
  ///
  /// In en, this message translates to:
  /// **'Other preferences'**
  String get fieldOtherPreferences;

  /// No description provided for @actionMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get actionMessage;

  /// No description provided for @actionRevealContact.
  ///
  /// In en, this message translates to:
  /// **'Reveal / request contact'**
  String get actionRevealContact;

  /// No description provided for @pleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in first'**
  String get pleaseSignIn;

  /// No description provided for @blockedNoReveal.
  ///
  /// In en, this message translates to:
  /// **'You can\'t view contact details of a blocked profile'**
  String get blockedNoReveal;

  /// No description provided for @contactRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Contact request pending'**
  String get contactRequestPending;

  /// No description provided for @signInToMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to send a message'**
  String get signInToMessage;

  /// No description provided for @profileInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile inactive'**
  String get profileInactiveTitle;

  /// No description provided for @profileInactiveReactivatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Your profile is deactivated. Reactivate it now to send messages?'**
  String get profileInactiveReactivatePrompt;

  /// No description provided for @actionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get actionNotNow;

  /// No description provided for @actionReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get actionReactivate;

  /// No description provided for @profileReactivated.
  ///
  /// In en, this message translates to:
  /// **'Profile reactivated'**
  String get profileReactivated;

  /// No description provided for @profileReactivateFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reactivate your profile. Please try again.'**
  String get profileReactivateFailed;

  /// No description provided for @messagingDisabledInactive.
  ///
  /// In en, this message translates to:
  /// **'This profile is not active. Messaging is turned off for now.'**
  String get messagingDisabledInactive;

  /// No description provided for @messagingDisabledBlocked.
  ///
  /// In en, this message translates to:
  /// **'Messaging is turned off for blocked profiles'**
  String get messagingDisabledBlocked;

  /// No description provided for @contactRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Contact request sent'**
  String get contactRequestSent;

  /// No description provided for @contactRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the request. Please try again.'**
  String get contactRequestFailed;

  /// No description provided for @acceptContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept contact request?'**
  String get acceptContactTitle;

  /// No description provided for @acceptContactBody.
  ///
  /// In en, this message translates to:
  /// **'Share contact details with {name}?'**
  String acceptContactBody(Object name);

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @contactRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Contact request accepted'**
  String get contactRequestAccepted;

  /// No description provided for @contactAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t accept the request. Please try again.'**
  String get contactAcceptFailed;

  /// No description provided for @interestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Interest sent to {name}'**
  String interestSentTo(Object name);

  /// No description provided for @interestSendFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your interest. Please try again.'**
  String get interestSendFailed;

  /// No description provided for @shortlistRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from shortlist'**
  String get shortlistRemoved;

  /// No description provided for @shortlistAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to shortlist'**
  String get shortlistAdded;

  /// No description provided for @shortlistFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update your shortlist. Please try again.'**
  String get shortlistFailed;

  /// No description provided for @contactDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get contactDetailsTitle;

  /// No description provided for @contactNoPhone.
  ///
  /// In en, this message translates to:
  /// **'This member has not added a phone number yet.'**
  String get contactNoPhone;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone: {number}'**
  String contactPhone(Object number);

  /// No description provided for @contactWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp: {number}'**
  String contactWhatsapp(Object number);

  /// No description provided for @contactLimitUpgrade.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your plan\'s contact limit. Upgrade your plan to see more.'**
  String get contactLimitUpgrade;

  /// No description provided for @contactRevealFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t show the contact details. Please try again.'**
  String get contactRevealFailed;

  /// No description provided for @messageTo.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String messageTo(Object name);

  /// No description provided for @messageHintLong.
  ///
  /// In en, this message translates to:
  /// **'Type your message…'**
  String get messageHintLong;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get messageSent;

  /// No description provided for @messageSendFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send your message. Please try again.'**
  String get messageSendFailed;

  /// No description provided for @blockProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Block profile'**
  String get blockProfileAction;

  /// No description provided for @reportProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Report profile'**
  String get reportProfileAction;

  /// No description provided for @blockProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Block profile?'**
  String get blockProfileTitle;

  /// No description provided for @blockProfileBody.
  ///
  /// In en, this message translates to:
  /// **'You will no longer see {name}, and they won\'t be able to contact you.'**
  String blockProfileBody(Object name);

  /// No description provided for @profileBlocked.
  ///
  /// In en, this message translates to:
  /// **'Profile blocked'**
  String get profileBlocked;

  /// No description provided for @blockFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t block this profile. Please try again.'**
  String get blockFailed;

  /// No description provided for @actionBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get actionBlock;

  /// No description provided for @reportProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Report profile'**
  String get reportProfileTitle;

  /// No description provided for @reportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReason;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetails;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you for helping keep the community safe.'**
  String get reportSubmitted;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t submit your report. Please try again.'**
  String get reportFailed;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// No description provided for @similarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No similar profiles found yet.'**
  String get similarEmpty;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @previousPhoto.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get previousPhoto;

  /// No description provided for @nextPhoto.
  ///
  /// In en, this message translates to:
  /// **'Next photo'**
  String get nextPhoto;

  /// No description provided for @photoCounter.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String photoCounter(int current, int total);

  /// No description provided for @ageYearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String ageYearsOld(int age);

  /// No description provided for @incomeLpa.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} LPA'**
  String incomeLpa(String amount);

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String weightKg(String weight);

  /// No description provided for @ageRange.
  ///
  /// In en, this message translates to:
  /// **'{min} - {max} years'**
  String ageRange(int min, int max);

  /// No description provided for @heightRangeCm.
  ///
  /// In en, this message translates to:
  /// **'{min} - {max} cm'**
  String heightRangeCm(String min, String max);

  /// No description provided for @incomeRangeLpa.
  ///
  /// In en, this message translates to:
  /// **'₹{min} - {max} LPA'**
  String incomeRangeLpa(String min, String max);

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @ageCityShort.
  ///
  /// In en, this message translates to:
  /// **'{age} • {city}'**
  String ageCityShort(int age, String city);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try Me For Your Partner Selection'**
  String get homeSubtitle;

  /// No description provided for @statMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get statMatches;

  /// No description provided for @statShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get statShortlisted;

  /// No description provided for @statViewedYou.
  ///
  /// In en, this message translates to:
  /// **'Viewed you'**
  String get statViewedYou;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingWithName(Object greeting, Object name);

  /// No description provided for @homeTopPicks.
  ///
  /// In en, this message translates to:
  /// **'Top picks for you'**
  String get homeTopPicks;

  /// No description provided for @homeYourMatches.
  ///
  /// In en, this message translates to:
  /// **'Your matches'**
  String get homeYourMatches;

  /// No description provided for @homeViewedYou.
  ///
  /// In en, this message translates to:
  /// **'Viewed you'**
  String get homeViewedYou;

  /// No description provided for @homeNewThisWeek.
  ///
  /// In en, this message translates to:
  /// **'New this week'**
  String get homeNewThisWeek;

  /// No description provided for @homeViewedByYou.
  ///
  /// In en, this message translates to:
  /// **'Viewed by you'**
  String get homeViewedByYou;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeEmptyTopPicks.
  ///
  /// In en, this message translates to:
  /// **'No top picks yet. Highly compatible profiles will appear here.'**
  String get homeEmptyTopPicks;

  /// No description provided for @homeEmptyMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet. Update your preferences or try searching.'**
  String get homeEmptyMatches;

  /// No description provided for @homeEmptyViewedYou.
  ///
  /// In en, this message translates to:
  /// **'No one has viewed your profile yet.'**
  String get homeEmptyViewedYou;

  /// No description provided for @homeEmptyNewThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No new profiles in the last 7 days.'**
  String get homeEmptyNewThisWeek;

  /// No description provided for @homeEmptyViewedByYou.
  ///
  /// In en, this message translates to:
  /// **'Start viewing profiles to see them here.'**
  String get homeEmptyViewedByYou;

  /// No description provided for @homeCompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get homeCompleteProfileTitle;

  /// No description provided for @homeCompleteProfileProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete · Get better matches with full details'**
  String homeCompleteProfileProgress(int percent);

  /// No description provided for @homeCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get homeCompleteAction;

  /// No description provided for @homeDeactivatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is deactivated'**
  String get homeDeactivatedTitle;

  /// No description provided for @homeDeactivatedBody.
  ///
  /// In en, this message translates to:
  /// **'Reactivate your profile to send and receive messages and appear in searches.'**
  String get homeDeactivatedBody;

  /// No description provided for @statLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}: {count}'**
  String statLabel(String label, int count);

  /// No description provided for @matchesTabMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchesTabMatches;

  /// No description provided for @matchesTabTopPicks.
  ///
  /// In en, this message translates to:
  /// **'Top picks'**
  String get matchesTabTopPicks;

  /// No description provided for @matchesTabInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get matchesTabInterests;

  /// No description provided for @matchesTabShortlistedByYou.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted by you'**
  String get matchesTabShortlistedByYou;

  /// No description provided for @matchesTabShortlistedYou.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted you'**
  String get matchesTabShortlistedYou;

  /// No description provided for @matchesTabViewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get matchesTabViewed;

  /// No description provided for @matchesTabViewedYou.
  ///
  /// In en, this message translates to:
  /// **'Viewed you'**
  String get matchesTabViewedYou;

  /// No description provided for @matchesTabAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get matchesTabAccepted;

  /// No description provided for @matchesChooseList.
  ///
  /// In en, this message translates to:
  /// **'Choose a list'**
  String get matchesChooseList;

  /// No description provided for @matchesPreviousList.
  ///
  /// In en, this message translates to:
  /// **'Previous list'**
  String get matchesPreviousList;

  /// No description provided for @matchesNextList.
  ///
  /// In en, this message translates to:
  /// **'Next list'**
  String get matchesNextList;

  /// No description provided for @signInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get signInRequiredTitle;

  /// No description provided for @signInRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to find your match and connect with compatible profiles'**
  String get signInRequiredBody;

  /// No description provided for @matchesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get matchesEmptyTitle;

  /// No description provided for @matchesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get better matches'**
  String get matchesEmptyBody;

  /// No description provided for @actionCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get actionCompleteProfile;

  /// No description provided for @interestsNoneReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'No interests received'**
  String get interestsNoneReceivedTitle;

  /// No description provided for @interestsNoneReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile will receive interests from compatible matches'**
  String get interestsNoneReceivedBody;

  /// No description provided for @actionImproveProfile.
  ///
  /// In en, this message translates to:
  /// **'Improve profile'**
  String get actionImproveProfile;

  /// No description provided for @topPicksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No top picks yet'**
  String get topPicksEmptyTitle;

  /// No description provided for @topPicksEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Highly compatible profiles will appear here once matches are available'**
  String get topPicksEmptyBody;

  /// No description provided for @actionRefreshMatches.
  ///
  /// In en, this message translates to:
  /// **'Refresh matches'**
  String get actionRefreshMatches;

  /// No description provided for @shortlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No shortlisted profiles'**
  String get shortlistEmptyTitle;

  /// No description provided for @shortlistEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Browse profiles and shortlist the ones you like'**
  String get shortlistEmptyBody;

  /// No description provided for @actionBrowseProfiles.
  ///
  /// In en, this message translates to:
  /// **'Browse profiles'**
  String get actionBrowseProfiles;

  /// No description provided for @shortlistedYouEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No one has shortlisted you yet'**
  String get shortlistedYouEmptyTitle;

  /// No description provided for @shortlistedYouEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'As more people discover your profile, you\'ll see them here'**
  String get shortlistedYouEmptyBody;

  /// No description provided for @viewedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No profile views'**
  String get viewedEmptyTitle;

  /// No description provided for @viewedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start viewing profiles to see them here'**
  String get viewedEmptyBody;

  /// No description provided for @viewedYouEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No profile views yet'**
  String get viewedYouEmptyTitle;

  /// No description provided for @viewedYouEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'People who view your profile will appear here'**
  String get viewedYouEmptyBody;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @acceptedNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No accepted connections'**
  String get acceptedNoneTitle;

  /// No description provided for @acceptedNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Accepted interests will appear here'**
  String get acceptedNoneBody;

  /// No description provided for @matchesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading matches…'**
  String get matchesLoading;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorLoadMatches.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your matches. Check your connection and try again.'**
  String get errorLoadMatches;

  /// No description provided for @interestAcceptedFrom.
  ///
  /// In en, this message translates to:
  /// **'You accepted {name}\'s interest'**
  String interestAcceptedFrom(Object name);

  /// No description provided for @interestRejectedFrom.
  ///
  /// In en, this message translates to:
  /// **'You declined {name}\'s interest'**
  String interestRejectedFrom(Object name);

  /// No description provided for @restartToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please restart the app to sign in.'**
  String get restartToSignIn;

  /// No description provided for @religionHindu.
  ///
  /// In en, this message translates to:
  /// **'Hindu'**
  String get religionHindu;

  /// No description provided for @religionMuslim.
  ///
  /// In en, this message translates to:
  /// **'Muslim'**
  String get religionMuslim;

  /// No description provided for @religionChristian.
  ///
  /// In en, this message translates to:
  /// **'Christian'**
  String get religionChristian;

  /// No description provided for @religionSikh.
  ///
  /// In en, this message translates to:
  /// **'Sikh'**
  String get religionSikh;

  /// No description provided for @religionJain.
  ///
  /// In en, this message translates to:
  /// **'Jain'**
  String get religionJain;

  /// No description provided for @religionBuddhist.
  ///
  /// In en, this message translates to:
  /// **'Buddhist'**
  String get religionBuddhist;

  /// No description provided for @optionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get optionOther;

  /// No description provided for @maritalNeverMarried.
  ///
  /// In en, this message translates to:
  /// **'Never married'**
  String get maritalNeverMarried;

  /// No description provided for @maritalDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get maritalDivorced;

  /// No description provided for @maritalWidowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get maritalWidowed;

  /// No description provided for @maritalSeparated.
  ///
  /// In en, this message translates to:
  /// **'Separated'**
  String get maritalSeparated;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @createdBySelf.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get createdBySelf;

  /// No description provided for @createdBySibling.
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get createdBySibling;

  /// No description provided for @createdByParents.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get createdByParents;

  /// No description provided for @createdByGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get createdByGuardian;

  /// No description provided for @workBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get workBusiness;

  /// No description provided for @workSalaried.
  ///
  /// In en, this message translates to:
  /// **'Salaried'**
  String get workSalaried;

  /// No description provided for @workNotWorking.
  ///
  /// In en, this message translates to:
  /// **'Currently not working'**
  String get workNotWorking;

  /// No description provided for @registrationProfileCreated.
  ///
  /// In en, this message translates to:
  /// **'Profile created'**
  String get registrationProfileCreated;

  /// No description provided for @registrationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your details. Please try again.'**
  String get registrationSaveFailed;

  /// No description provided for @registrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete registration'**
  String get registrationTitle;

  /// No description provided for @registrationEmailFromLogin.
  ///
  /// In en, this message translates to:
  /// **'Email (from sign-in)'**
  String get registrationEmailFromLogin;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get validationNameRequired;

  /// No description provided for @fieldGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get fieldGender;

  /// No description provided for @validationSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender'**
  String get validationSelectGender;

  /// No description provided for @fieldDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get fieldDateOfBirth;

  /// No description provided for @validationSelectDob.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get validationSelectDob;

  /// No description provided for @fieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get fieldPhone;

  /// No description provided for @validationPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get validationPhone;

  /// No description provided for @fieldWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get fieldWhatsapp;

  /// No description provided for @validationWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid WhatsApp number'**
  String get validationWhatsapp;

  /// No description provided for @fieldProfileCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Profile created by'**
  String get fieldProfileCreatedBy;

  /// No description provided for @validationSelectOne.
  ///
  /// In en, this message translates to:
  /// **'Please choose one'**
  String get validationSelectOne;

  /// No description provided for @fieldWorkStatus.
  ///
  /// In en, this message translates to:
  /// **'Work status'**
  String get fieldWorkStatus;

  /// No description provided for @fieldOccupationCategory.
  ///
  /// In en, this message translates to:
  /// **'Occupation category'**
  String get fieldOccupationCategory;

  /// No description provided for @fieldQualification.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get fieldQualification;

  /// No description provided for @fieldDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Discipline / field'**
  String get fieldDiscipline;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @fieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get fieldCity;

  /// No description provided for @validationReligion.
  ///
  /// In en, this message translates to:
  /// **'Please select a religion'**
  String get validationReligion;

  /// No description provided for @validationCaste.
  ///
  /// In en, this message translates to:
  /// **'Please select a caste'**
  String get validationCaste;

  /// No description provided for @fieldSubCasteOptional.
  ///
  /// In en, this message translates to:
  /// **'Sub-caste (optional)'**
  String get fieldSubCasteOptional;

  /// No description provided for @fieldState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get fieldState;

  /// No description provided for @validationState.
  ///
  /// In en, this message translates to:
  /// **'Please select a state'**
  String get validationState;

  /// No description provided for @fieldDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get fieldDistrict;

  /// No description provided for @validationDistrict.
  ///
  /// In en, this message translates to:
  /// **'Please select a district'**
  String get validationDistrict;

  /// No description provided for @actionSaveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get actionSaveAndContinue;

  /// No description provided for @registrationLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you are most comfortable with'**
  String get registrationLanguageHint;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profile…'**
  String get profileLoading;

  /// No description provided for @profileSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your profile, favourites and personalised recommendations'**
  String get profileSignInBody;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan: {plan}'**
  String planLabel(Object plan);

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get planGold;

  /// No description provided for @planPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get planPlatinum;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verification required'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationBody.
  ///
  /// In en, this message translates to:
  /// **'Please open the verification link in your email to finish setting up your account.'**
  String get emailVerificationBody;

  /// No description provided for @actionResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get actionResend;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changePhoto;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(Object date);

  /// No description provided for @actionEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get actionEditProfile;

  /// No description provided for @actionManagePhotos.
  ///
  /// In en, this message translates to:
  /// **'Manage photos'**
  String get actionManagePhotos;

  /// No description provided for @statComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get statComplete;

  /// No description provided for @statIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get statIncomplete;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActionsTitle;

  /// No description provided for @quickFavorites.
  ///
  /// In en, this message translates to:
  /// **'My favourites'**
  String get quickFavorites;

  /// No description provided for @quickFavoritesSub.
  ///
  /// In en, this message translates to:
  /// **'View your interests'**
  String get quickFavoritesSub;

  /// No description provided for @quickMatchesSub.
  ///
  /// In en, this message translates to:
  /// **'See your matches'**
  String get quickMatchesSub;

  /// No description provided for @quickCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile completion'**
  String get quickCompletion;

  /// No description provided for @quickCompletionSub.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get quickCompletionSub;

  /// No description provided for @quickRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh data'**
  String get quickRefresh;

  /// No description provided for @quickRefreshSub.
  ///
  /// In en, this message translates to:
  /// **'Reload your profile and suggestions'**
  String get quickRefreshSub;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsHelpSub.
  ///
  /// In en, this message translates to:
  /// **'Get help and contact us'**
  String get settingsHelpSub;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSub.
  ///
  /// In en, this message translates to:
  /// **'App information and licences'**
  String get settingsAboutSub;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordSub.
  ///
  /// In en, this message translates to:
  /// **'Get an email link to set a new password'**
  String get settingsChangePasswordSub;

  /// No description provided for @changePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'We will send a link to {email} so you can set a new password.'**
  String changePasswordConfirm(Object email);

  /// No description provided for @changePasswordSend.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get changePasswordSend;

  /// No description provided for @changePasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Check {email} for the link to set a new password.'**
  String changePasswordSent(Object email);

  /// No description provided for @changePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the link. Please try again.'**
  String get changePasswordFailed;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A matrimony app for Tamil and Indian families around the world.'**
  String get aboutDescription;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Please check your inbox.'**
  String get verificationEmailSent;

  /// No description provided for @verificationEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the verification email. Please try again.'**
  String get verificationEmailFailed;

  /// No description provided for @photoTake.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get photoTake;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoGallery;

  /// No description provided for @photoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get photoAdd;

  /// No description provided for @photoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemove;

  /// No description provided for @photoPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get photoPrimary;

  /// No description provided for @photoMakePrimary.
  ///
  /// In en, this message translates to:
  /// **'Make primary'**
  String get photoMakePrimary;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account actions'**
  String get accountActions;

  /// No description provided for @actionReactivateProfile.
  ///
  /// In en, this message translates to:
  /// **'Reactivate profile'**
  String get actionReactivateProfile;

  /// No description provided for @actionDeactivateProfile.
  ///
  /// In en, this message translates to:
  /// **'Deactivate profile'**
  String get actionDeactivateProfile;

  /// No description provided for @actionDeleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get actionDeleteProfile;

  /// No description provided for @profileNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Your profile hasn\'t loaded yet. Please try again.'**
  String get profileNotLoaded;

  /// No description provided for @deactivateBody.
  ///
  /// In en, this message translates to:
  /// **'Deactivating hides your profile from searches and turns off incoming messages. You can reactivate it any time by editing your profile.'**
  String get deactivateBody;

  /// No description provided for @actionDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get actionDeactivate;

  /// No description provided for @profileDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Profile deactivated'**
  String get profileDeactivated;

  /// No description provided for @profileDeactivateFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t deactivate your profile. Please try again.'**
  String get profileDeactivateFailed;

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'Deleting your profile permanently removes your profile records. A minimal archive is kept so support can restore it if needed. This cannot be undone.'**
  String get deleteBody;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @profileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Profile deleted. Signing you out…'**
  String get profileDeleted;

  /// No description provided for @profileDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your profile. Please try again.'**
  String get profileDeleteFailed;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @signingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get signingOut;

  /// No description provided for @profileStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Your profile is active'**
  String get profileStatusActive;

  /// No description provided for @profileStatusDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Your profile is deactivated'**
  String get profileStatusDeactivated;

  /// No description provided for @profileStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'No profile found. Create your profile to get matches.'**
  String get profileStatusMissing;

  /// No description provided for @noProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'No profile found'**
  String get noProfileTitle;

  /// No description provided for @noProfileBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a profile linked to your account. You can still browse, but to get personalised matches, please create your profile.'**
  String get noProfileBody;

  /// No description provided for @createProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create your profile. Please try again.'**
  String get createProfileFailed;

  /// No description provided for @actionCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Create my profile'**
  String get actionCreateProfile;

  /// No description provided for @profileRestored.
  ///
  /// In en, this message translates to:
  /// **'Profile restored from archive.'**
  String get profileRestored;

  /// No description provided for @noArchivedProfile.
  ///
  /// In en, this message translates to:
  /// **'No archived profile found to restore.'**
  String get noArchivedProfile;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t restore your profile. Please try again.'**
  String get restoreFailed;

  /// No description provided for @actionRestoreProfile.
  ///
  /// In en, this message translates to:
  /// **'Restore my profile'**
  String get actionRestoreProfile;

  /// No description provided for @diagnosticsPrinted.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics written to the console'**
  String get diagnosticsPrinted;

  /// No description provided for @actionPrintDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Print diagnostics'**
  String get actionPrintDiagnostics;

  /// No description provided for @myProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfileTitle;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get fieldAge;

  /// No description provided for @fieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get fieldLocation;

  /// No description provided for @actionEditMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit my profile'**
  String get actionEditMyProfile;

  /// No description provided for @refreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile data refreshed'**
  String get refreshSuccess;

  /// No description provided for @refreshNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh: you\'re not signed in'**
  String get refreshNotSignedIn;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get defaultUserName;

  /// No description provided for @statInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get statInterests;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search profiles'**
  String get searchTitle;

  /// No description provided for @savedSearchesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Saved searches'**
  String get savedSearchesTooltip;

  /// No description provided for @contactRequestsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Contact requests'**
  String get contactRequestsTooltip;

  /// No description provided for @actionResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get actionResetFilters;

  /// No description provided for @searchTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: adjust the filters and tap Search to see results here.'**
  String get searchTip;

  /// No description provided for @searchLocationPrefs.
  ///
  /// In en, this message translates to:
  /// **'Location preferences'**
  String get searchLocationPrefs;

  /// No description provided for @searchBasicPrefs.
  ///
  /// In en, this message translates to:
  /// **'Basic preferences'**
  String get searchBasicPrefs;

  /// No description provided for @fieldSubCasteShort.
  ///
  /// In en, this message translates to:
  /// **'Sub-caste'**
  String get fieldSubCasteShort;

  /// No description provided for @searchMoreEducations.
  ///
  /// In en, this message translates to:
  /// **'More education options'**
  String get searchMoreEducations;

  /// No description provided for @searchMoreOccupations.
  ///
  /// In en, this message translates to:
  /// **'More occupations'**
  String get searchMoreOccupations;

  /// No description provided for @searchMoreCastes.
  ///
  /// In en, this message translates to:
  /// **'More castes'**
  String get searchMoreCastes;

  /// No description provided for @searchRangePrefs.
  ///
  /// In en, this message translates to:
  /// **'Range preferences'**
  String get searchRangePrefs;

  /// No description provided for @filterOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get filterOnlineNow;

  /// No description provided for @filterRecentlyActive.
  ///
  /// In en, this message translates to:
  /// **'Recently active'**
  String get filterRecentlyActive;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortYoungerFirst.
  ///
  /// In en, this message translates to:
  /// **'Younger first'**
  String get sortYoungerFirst;

  /// No description provided for @sortOlderFirst.
  ///
  /// In en, this message translates to:
  /// **'Older first'**
  String get sortOlderFirst;

  /// No description provided for @sortHigherIncome.
  ///
  /// In en, this message translates to:
  /// **'Higher income'**
  String get sortHigherIncome;

  /// No description provided for @actionSaveSearch.
  ///
  /// In en, this message translates to:
  /// **'Save this search'**
  String get actionSaveSearch;

  /// No description provided for @quickSearch.
  ///
  /// In en, this message translates to:
  /// **'Quick search (no filters)'**
  String get quickSearch;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search for profiles'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Use the filters above to find compatible matches'**
  String get searchEmptyBody;

  /// No description provided for @contactAvailable.
  ///
  /// In en, this message translates to:
  /// **'Contact available'**
  String get contactAvailable;

  /// No description provided for @contactStateRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get contactStateRequestSent;

  /// No description provided for @contactStateRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'Request received'**
  String get contactStateRequestReceived;

  /// No description provided for @recentChip.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentChip;

  /// No description provided for @joinedWithinTooltip.
  ///
  /// In en, this message translates to:
  /// **'Joined within days'**
  String get joinedWithinTooltip;

  /// No description provided for @actionClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get actionClearAll;

  /// No description provided for @completeRegistrationFirst.
  ///
  /// In en, this message translates to:
  /// **'Please complete registration first.'**
  String get completeRegistrationFirst;

  /// No description provided for @saveSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this search'**
  String get saveSearchTitle;

  /// No description provided for @saveSearchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chennai IT, 25-30, Hindu'**
  String get saveSearchHint;

  /// No description provided for @savedSearchesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved searches yet.'**
  String get savedSearchesEmpty;

  /// No description provided for @deleteSavedSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete saved search?'**
  String get deleteSavedSearchTitle;

  /// No description provided for @runSearch.
  ///
  /// In en, this message translates to:
  /// **'Run search'**
  String get runSearch;

  /// No description provided for @fieldAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get fieldAbout;

  /// No description provided for @fieldLocationPlain.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get fieldLocationPlain;

  /// No description provided for @searchLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get searchLoading;

  /// No description provided for @rangeAge.
  ///
  /// In en, this message translates to:
  /// **'Age: {min} - {max} years'**
  String rangeAge(int min, int max);

  /// No description provided for @rangeHeight.
  ///
  /// In en, this message translates to:
  /// **'Height: {min} - {max} cm'**
  String rangeHeight(int min, int max);

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'{value} cm'**
  String heightCm(int value);

  /// No description provided for @rangeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income: {min}L - {max}L per year'**
  String rangeIncome(String min, String max);

  /// No description provided for @incomeLakhShort.
  ///
  /// In en, this message translates to:
  /// **'{value}L'**
  String incomeLakhShort(String value);

  /// No description provided for @profilesFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No profiles found} =1{1 profile found} other{{count} profiles found}}'**
  String profilesFound(int count);

  /// No description provided for @profilesRecommended.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recommended profile} other{{count} recommended profiles}}'**
  String profilesRecommended(int count);

  /// No description provided for @chipLabelValue.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String chipLabelValue(Object label, Object value);

  /// No description provided for @chipAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Age {min}-{max}'**
  String chipAgeRange(int min, int max);

  /// No description provided for @chipHeightRange.
  ///
  /// In en, this message translates to:
  /// **'Height {min}-{max} cm'**
  String chipHeightRange(int min, int max);

  /// No description provided for @chipIncomeRange.
  ///
  /// In en, this message translates to:
  /// **'Income {min}-{max}L'**
  String chipIncomeRange(String min, String max);

  /// No description provided for @joinedWithinDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Joined: last day} other{Joined: last {days} days}}'**
  String joinedWithinDays(int days);

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search didn\'t work. Please try again.'**
  String get searchFailed;

  /// No description provided for @filtersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the filter options. Please try again.'**
  String get filtersLoadFailed;

  /// No description provided for @defaultSearchName.
  ///
  /// In en, this message translates to:
  /// **'Search {date}'**
  String defaultSearchName(Object date);

  /// No description provided for @savedSearchNamed.
  ///
  /// In en, this message translates to:
  /// **'Saved search \"{name}\"'**
  String savedSearchNamed(Object name);

  /// No description provided for @saveSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save this search. Please try again.'**
  String get saveSearchFailed;

  /// No description provided for @deleteSavedSearchBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed.'**
  String deleteSavedSearchBody(Object name);

  /// No description provided for @savedSearchAlertsOn.
  ///
  /// In en, this message translates to:
  /// **'Alerts on • {date}'**
  String savedSearchAlertsOn(Object date);

  /// No description provided for @savedSearchAlertsOff.
  ///
  /// In en, this message translates to:
  /// **'Alerts off • {date}'**
  String savedSearchAlertsOff(Object date);

  /// No description provided for @toggleFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t change this setting. Please try again.'**
  String get toggleFailed;

  /// No description provided for @langTamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get langTamil;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langTelugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get langTelugu;

  /// No description provided for @langKannada.
  ///
  /// In en, this message translates to:
  /// **'Kannada'**
  String get langKannada;

  /// No description provided for @langMalayalam.
  ///
  /// In en, this message translates to:
  /// **'Malayalam'**
  String get langMalayalam;

  /// No description provided for @langHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get langHindi;

  /// No description provided for @editSectionLocationCareer.
  ///
  /// In en, this message translates to:
  /// **'Location & career'**
  String get editSectionLocationCareer;

  /// No description provided for @editTabLocationCareer.
  ///
  /// In en, this message translates to:
  /// **'Location & career'**
  String get editTabLocationCareer;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editTabBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get editTabBasic;

  /// No description provided for @editTabContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get editTabContact;

  /// No description provided for @editTabFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get editTabFamily;

  /// No description provided for @editTabPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner preferences'**
  String get editTabPartner;

  /// No description provided for @editTabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get editTabPhotos;

  /// No description provided for @profileLoadingYours.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile…'**
  String get profileLoadingYours;

  /// No description provided for @editEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in email. Only you can see it.'**
  String get editEmailHelper;

  /// No description provided for @fieldDobRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth *'**
  String get fieldDobRequired;

  /// No description provided for @fieldReligionRequired.
  ///
  /// In en, this message translates to:
  /// **'Religion *'**
  String get fieldReligionRequired;

  /// No description provided for @fieldCasteRequired.
  ///
  /// In en, this message translates to:
  /// **'Caste *'**
  String get fieldCasteRequired;

  /// No description provided for @fieldStateRequired.
  ///
  /// In en, this message translates to:
  /// **'State *'**
  String get fieldStateRequired;

  /// No description provided for @fieldDistrictRequired.
  ///
  /// In en, this message translates to:
  /// **'District *'**
  String get fieldDistrictRequired;

  /// No description provided for @fieldEducationRequired.
  ///
  /// In en, this message translates to:
  /// **'Education *'**
  String get fieldEducationRequired;

  /// No description provided for @fieldHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get fieldHeightCm;

  /// No description provided for @fieldWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get fieldWeightKg;

  /// No description provided for @sectionContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact information'**
  String get sectionContactInfo;

  /// No description provided for @fieldPhoneShort.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get fieldPhoneShort;

  /// No description provided for @fieldAltPhone.
  ///
  /// In en, this message translates to:
  /// **'Alternate phone'**
  String get fieldAltPhone;

  /// No description provided for @fieldCurrentAddress.
  ///
  /// In en, this message translates to:
  /// **'Current address'**
  String get fieldCurrentAddress;

  /// No description provided for @fieldPermanentAddress.
  ///
  /// In en, this message translates to:
  /// **'Permanent address'**
  String get fieldPermanentAddress;

  /// No description provided for @showPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Show phone number'**
  String get showPhoneNumber;

  /// No description provided for @showAddress.
  ///
  /// In en, this message translates to:
  /// **'Show address'**
  String get showAddress;

  /// No description provided for @fieldFamilyDetails.
  ///
  /// In en, this message translates to:
  /// **'Family details'**
  String get fieldFamilyDetails;

  /// No description provided for @fieldMinAge.
  ///
  /// In en, this message translates to:
  /// **'Min age'**
  String get fieldMinAge;

  /// No description provided for @fieldMaxAge.
  ///
  /// In en, this message translates to:
  /// **'Max age'**
  String get fieldMaxAge;

  /// No description provided for @fieldMinHeight.
  ///
  /// In en, this message translates to:
  /// **'Min height (cm)'**
  String get fieldMinHeight;

  /// No description provided for @fieldMaxHeight.
  ///
  /// In en, this message translates to:
  /// **'Max height (cm)'**
  String get fieldMaxHeight;

  /// No description provided for @fieldPreferredDistricts.
  ///
  /// In en, this message translates to:
  /// **'Preferred districts'**
  String get fieldPreferredDistricts;

  /// No description provided for @fieldPreferredOccupations.
  ///
  /// In en, this message translates to:
  /// **'Preferred occupations'**
  String get fieldPreferredOccupations;

  /// No description provided for @fieldMinIncome.
  ///
  /// In en, this message translates to:
  /// **'Min income'**
  String get fieldMinIncome;

  /// No description provided for @fieldMaxIncome.
  ///
  /// In en, this message translates to:
  /// **'Max income'**
  String get fieldMaxIncome;

  /// No description provided for @fieldPreferredMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Preferred marital status'**
  String get fieldPreferredMaritalStatus;

  /// No description provided for @profilePhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photos'**
  String get profilePhotosTitle;

  /// No description provided for @actionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get actionPrevious;

  /// No description provided for @profileSavedLoadingMatches.
  ///
  /// In en, this message translates to:
  /// **'Profile saved. Loading your matches…'**
  String get profileSavedLoadingMatches;

  /// No description provided for @fillMandatoryFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields marked with * to continue.'**
  String get fillMandatoryFields;

  /// No description provided for @actionFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get actionFinish;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @mandatoryBanner.
  ///
  /// In en, this message translates to:
  /// **'Fields marked with * are needed to show you relevant matches.'**
  String get mandatoryBanner;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @chipsInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type and press + to add'**
  String get chipsInputHint;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @savedBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic information saved'**
  String get savedBasic;

  /// No description provided for @savedBasicAuto.
  ///
  /// In en, this message translates to:
  /// **'Basic information auto-saved'**
  String get savedBasicAuto;

  /// No description provided for @savedLocation.
  ///
  /// In en, this message translates to:
  /// **'Location & career saved'**
  String get savedLocation;

  /// No description provided for @savedLocationAuto.
  ///
  /// In en, this message translates to:
  /// **'Location & career auto-saved'**
  String get savedLocationAuto;

  /// No description provided for @savedContact.
  ///
  /// In en, this message translates to:
  /// **'Contact information saved'**
  String get savedContact;

  /// No description provided for @savedContactAuto.
  ///
  /// In en, this message translates to:
  /// **'Contact information auto-saved'**
  String get savedContactAuto;

  /// No description provided for @savedFamily.
  ///
  /// In en, this message translates to:
  /// **'Family information saved'**
  String get savedFamily;

  /// No description provided for @savedFamilyAuto.
  ///
  /// In en, this message translates to:
  /// **'Family information auto-saved'**
  String get savedFamilyAuto;

  /// No description provided for @savedPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner preferences saved'**
  String get savedPartner;

  /// No description provided for @savedPartnerAuto.
  ///
  /// In en, this message translates to:
  /// **'Partner preferences auto-saved'**
  String get savedPartnerAuto;

  /// No description provided for @savedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos updated'**
  String get savedPhotos;

  /// No description provided for @profileStillLoading.
  ///
  /// In en, this message translates to:
  /// **'Your profile is still loading. Please try again in a moment.'**
  String get profileStillLoading;

  /// No description provided for @fillDobReligionCaste.
  ///
  /// In en, this message translates to:
  /// **'Please fill in your date of birth, religion and caste'**
  String get fillDobReligionCaste;

  /// No description provided for @photosGuidance.
  ///
  /// In en, this message translates to:
  /// **'Add up to 3 clear photos. Crop to show your face. Avoid filters and group photos.'**
  String get photosGuidance;

  /// No description provided for @removePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove photo?'**
  String get removePhotoTitle;

  /// No description provided for @removePhotoBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete the photo from storage.'**
  String get removePhotoBody;

  /// No description provided for @autoSavedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Saved automatically: {message}'**
  String autoSavedPrefix(Object message);

  /// No description provided for @autoSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save automatically. Your changes are still here; tap Save to try again.'**
  String get autoSaveFailed;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your changes. Please try again.'**
  String get saveFailed;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldRequired(Object field);

  /// No description provided for @photoSlot.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String photoSlot(int number);

  /// No description provided for @familyNuclear.
  ///
  /// In en, this message translates to:
  /// **'Nuclear'**
  String get familyNuclear;

  /// No description provided for @familyJoint.
  ///
  /// In en, this message translates to:
  /// **'Joint'**
  String get familyJoint;

  /// No description provided for @valuesTraditional.
  ///
  /// In en, this message translates to:
  /// **'Traditional'**
  String get valuesTraditional;

  /// No description provided for @valuesModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get valuesModern;

  /// No description provided for @valuesModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get valuesModerate;

  /// No description provided for @statusMiddleClass.
  ///
  /// In en, this message translates to:
  /// **'Middle class'**
  String get statusMiddleClass;

  /// No description provided for @statusUpperMiddleClass.
  ///
  /// In en, this message translates to:
  /// **'Upper middle class'**
  String get statusUpperMiddleClass;

  /// No description provided for @statusRich.
  ///
  /// In en, this message translates to:
  /// **'Affluent'**
  String get statusRich;

  /// No description provided for @toastInterestsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your interests were updated'**
  String get toastInterestsUpdated;

  /// No description provided for @toastInterestWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'An interest was withdrawn'**
  String get toastInterestWithdrawn;
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
