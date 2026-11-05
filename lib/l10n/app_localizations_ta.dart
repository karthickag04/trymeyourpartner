// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'TryMeYourPartner';

  @override
  String get commonOk => 'சரி';

  @override
  String get commonCancel => 'ரத்துசெய்';

  @override
  String get commonSave => 'சேமி';

  @override
  String get commonRetry => 'மீண்டும் முயலவும்';

  @override
  String get commonClose => 'மூடு';

  @override
  String get commonDone => 'முடிந்தது';

  @override
  String get commonNotSpecified => 'குறிப்பிடப்படவில்லை';

  @override
  String get commonSomethingWentWrong =>
      'ஏதோ தவறு நடந்துவிட்டது. மீண்டும் முயலவும்.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get languageLabel => 'மொழி';

  @override
  String get languageChooseTooltip => 'மொழியை மாற்று';

  @override
  String get authTagline =>
      'நம்பிக்கையுடன் உங்கள் வாழ்க்கைத் துணையைக் கண்டறியுங்கள்';

  @override
  String get authSignIn => 'உள்நுழைக';

  @override
  String get authSignUp => 'பதிவு செய்க';

  @override
  String get authEmailLabel => 'மின்னஞ்சல்';

  @override
  String get authEmailRequired => 'உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get authEmailInvalid => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get authPasswordLabel => 'கடவுச்சொல்';

  @override
  String get authPasswordRequired => 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String authPasswordTooShort(int min) {
    return 'கடவுச்சொல் குறைந்தது $min எழுத்துகள் கொண்டிருக்க வேண்டும்';
  }

  @override
  String get authShowPassword => 'கடவுச்சொல்லைக் காட்டு';

  @override
  String get authHidePassword => 'கடவுச்சொல்லை மறை';

  @override
  String get authForgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get authFullNameLabel => 'முழுப் பெயர்';

  @override
  String get authFullNameRequired => 'உங்கள் முழுப் பெயரை உள்ளிடவும்';

  @override
  String get authOrContinueWith => 'அல்லது இதன் மூலம் தொடரவும்';

  @override
  String get authContinueWithGoogle => 'Google மூலம் தொடரவும்';

  @override
  String get authWelcomeBack => 'மீண்டும் வருக!';

  @override
  String get authAccountCreated =>
      'உங்கள் கணக்கு வெற்றிகரமாக உருவாக்கப்பட்டது! TryMeYourPartner-க்கு உங்களை அன்புடன் வரவேற்கிறோம்!';

  @override
  String get authCheckEmailTitle => 'உங்கள் மின்னஞ்சலைப் பாருங்கள்';

  @override
  String authVerificationSent(String email) {
    return '$email என்ற முகவரிக்குச் சரிபார்ப்பு இணைப்பை அனுப்பியுள்ளோம்';
  }

  @override
  String get authVerificationInstruction =>
      'உங்கள் கணக்கைச் சரிபார்க்க, மின்னஞ்சலில் உள்ள இணைப்பைத் திறக்கவும்.';

  @override
  String get authSignedInWithGoogle => 'Google மூலம் உள்நுழைந்துவிட்டீர்கள்!';

  @override
  String get authGoogleUnavailableTitle =>
      'Google உள்நுழைவு தற்போது கிடைக்கவில்லை';

  @override
  String get authGoogleUnavailableBody =>
      'இந்தச் செயலியில் Google உள்நுழைவு இன்னும் அமைக்கப்படவில்லை. தயவுசெய்து மின்னஞ்சல் மூலம் உள்நுழையவும்.';

  @override
  String get authEnterEmailFirst =>
      'முதலில் உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get authPasswordResetSent =>
      'கடவுச்சொல்லை மீட்டமைக்கும் மின்னஞ்சல் அனுப்பப்பட்டது!';

  @override
  String get authErrorInvalidCredentials =>
      'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறாக உள்ளது.';

  @override
  String get authErrorAlreadyRegistered =>
      'இந்த மின்னஞ்சலில் ஏற்கனவே ஒரு கணக்கு உள்ளது. தயவுசெய்து உள்நுழையவும்.';

  @override
  String get authErrorEmailNotConfirmed =>
      'உள்நுழைவதற்கு முன் உங்கள் மின்னஞ்சலைச் சரிபார்க்கவும்.';

  @override
  String get authErrorSignUpFailed =>
      'உங்கள் கணக்கை உருவாக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get authErrorGoogleFailed =>
      'Google உள்நுழைவு வெற்றிபெறவில்லை. மீண்டும் முயலவும்.';

  @override
  String get authErrorNetwork =>
      'சேவையகத்தை அணுக முடியவில்லை. இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get splashTagline => 'குடும்பங்கள் சரியான வரனைக் கண்டடையும் இடம்';

  @override
  String get splashLoading => 'உங்களுக்காகத் தயாராகிறது...';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navMatches => 'வரன்கள்';

  @override
  String get navSearch => 'தேடல்';

  @override
  String get navInterests => 'விருப்பங்கள்';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String get toastNewMessage => 'புதிய செய்தி';

  @override
  String get toastInterestReceived =>
      'உங்களுக்கு ஒரு புதிய விருப்பம் வந்துள்ளது';

  @override
  String get toastInterestAccepted => 'உங்கள் விருப்பம் ஏற்றுக்கொள்ளப்பட்டது';

  @override
  String get toastInterestRejected => 'உங்கள் விருப்பம் ஏற்கப்படவில்லை';

  @override
  String get toastNewNotification => 'புதிய அறிவிப்பு';

  @override
  String interestsBadgeLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count புதிய விருப்பங்கள்',
      one: '1 புதிய விருப்பம்',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'இப்போது';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நிமிடங்களுக்கு முன்',
      one: '1 நிமிடத்திற்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மணி நேரத்திற்கு முன்',
      one: '1 மணி நேரத்திற்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'நேற்று';

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்களுக்கு முன்',
      one: '1 நாளுக்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String timeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count வாரங்களுக்கு முன்',
      one: '1 வாரத்திற்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மாதங்களுக்கு முன்',
      one: '1 மாதத்திற்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesShort(int count) {
    return '$count நி';
  }

  @override
  String timeHoursShort(int count) {
    return '$count ம';
  }

  @override
  String timeDaysShort(int count) {
    return '$count நா';
  }

  @override
  String get presenceOnline => 'ஆன்லைனில்';

  @override
  String get presenceOffline => 'ஆஃப்லைன்';

  @override
  String get profileNotAvailable => 'இந்தச் சுயவிவரம் தற்போது கிடைக்கவில்லை.';

  @override
  String get notificationsTitle => 'அறிவிப்புகள்';

  @override
  String get notificationsMarkAllRead => 'அனைத்தையும் படித்ததாகக் குறி';

  @override
  String get notificationsMarkRead => 'படித்ததாகக் குறி';

  @override
  String get notificationNewMessage => 'புதிய செய்தி';

  @override
  String get notificationNewInterest => 'புதிய விருப்பம்';

  @override
  String get notificationInterestAccepted => 'விருப்பம் ஏற்கப்பட்டது';

  @override
  String get notificationGeneric => 'அறிவிப்பு';

  @override
  String get contactRequestsTitle => 'தொடர்பு விவரக் கோரிக்கைகள்';

  @override
  String get contactRequestsReceived => 'பெற்றவை';

  @override
  String get contactRequestsSent => 'அனுப்பியவை';

  @override
  String get contactRequestsEmpty => 'இதுவரை கோரிக்கைகள் எதுவும் இல்லை';

  @override
  String contactRequestStatus(String status) {
    return 'நிலை: $status';
  }

  @override
  String get contactStatusPending => 'நிலுவையில் உள்ளது';

  @override
  String get contactStatusAccepted => 'ஏற்கப்பட்டது';

  @override
  String get contactStatusDeclined => 'மறுக்கப்பட்டது';

  @override
  String get contactStatusCancelled => 'ரத்துசெய்யப்பட்டது';

  @override
  String get actionAccept => 'ஏற்றுக்கொள்';

  @override
  String get actionDecline => 'மறு';

  @override
  String get messagesTitle => 'செய்திகள்';

  @override
  String get messagesSignInRequired =>
      'உங்கள் செய்திகளைப் பார்க்க உள்நுழையவும்';

  @override
  String get messagesLoadFailed => 'உங்கள் செய்திகளை ஏற்ற முடியவில்லை.';

  @override
  String get messagesEmpty => 'இதுவரை செய்திகள் எதுவும் இல்லை';

  @override
  String get profileNotActive => 'சுயவிவரம் செயலில் இல்லை';

  @override
  String get profileNotActiveNow => 'இந்தச் சுயவிவரம் தற்போது செயலில் இல்லை';

  @override
  String unreadCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'படிக்காத $count செய்திகள்',
      one: 'படிக்காத 1 செய்தி',
    );
    return '$_temp0';
  }

  @override
  String countOverflow(int max) {
    return '$max+';
  }

  @override
  String get chatLoadFailed => 'இந்த உரையாடலை ஏற்ற முடியவில்லை.';

  @override
  String get chatSendFailed =>
      'உங்கள் செய்தி அனுப்பப்படவில்லை. மீண்டும் முயலவும்.';

  @override
  String get chatMyProfileInactive =>
      'உங்கள் சுயவிவரம் செயலிழக்கப்பட்டுள்ளது. செய்திகள் அனுப்ப அதை மீண்டும் செயல்படுத்தவும்.';

  @override
  String get chatOtherProfileInactive =>
      'இந்தச் சுயவிவரம் தற்போது செயலில் இல்லை. முந்தைய செய்திகளைப் படிக்கலாம்; புதிய செய்திகளை அனுப்ப இயலாது.';

  @override
  String get chatTyping => 'தட்டச்சு செய்கிறார்…';

  @override
  String get chatSuggestPrompt => 'உரையாடலைத் தொடங்க ஒரு கேள்வியைப் பரிந்துரை';

  @override
  String get chatMessageHint => 'செய்தியைத் தட்டச்சு செய்யவும்';

  @override
  String get chatSend => 'அனுப்பு';

  @override
  String chatLastSeen(String time) {
    return 'கடைசியாகப் பார்த்தது $time';
  }

  @override
  String get chatStarterPassion =>
      'வேலைக்கு அப்பால் நீங்கள் மிகவும் விரும்பிச் செய்வது எது?';

  @override
  String get chatStarterWeekend =>
      'வார இறுதி திட்டம்: வீட்டில் ஓய்வா, வெளியே செல்வதா?';

  @override
  String get chatStarterSmallJoy =>
      'சமீபத்தில் உங்கள் நாளை இனிதாக்கிய ஒரு சிறிய மகிழ்ச்சி என்ன?';

  @override
  String get chatTickSent => 'அனுப்பப்பட்டது';

  @override
  String get chatTickDelivered => 'சென்றடைந்தது';

  @override
  String get chatTickRead => 'படிக்கப்பட்டது';

  @override
  String get notificationsTabAccepted => 'ஏற்கப்பட்டவை';

  @override
  String get notificationsTabInterests => 'விருப்பங்கள்';

  @override
  String get notificationsTabContactRequests => 'தொடர்புக் கோரிக்கைகள்';

  @override
  String newItemsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count புதியவை',
      one: '1 புதியது',
    );
    return '$_temp0';
  }

  @override
  String get acceptedEmptyTitle => 'இதுவரை ஏற்கப்பட்ட இணைப்புகள் இல்லை';

  @override
  String get acceptedEmptySubtitle =>
      'விருப்பங்கள் ஏற்கப்பட்டதும் அவை இங்கே தோன்றும்.';

  @override
  String get interestsEmptyTitle => 'புதிய விருப்பங்கள் எதுவும் இல்லை';

  @override
  String get interestsEmptySubtitle =>
      'உங்களுக்கு வரும் விருப்பங்கள் இங்கே தோன்றும்.';

  @override
  String get contactReceivedHeader => 'பெற்றவை (ஒப்புதல் அல்லது மறுப்பு)';

  @override
  String contactFrom(Object name) {
    return 'அனுப்பியவர்: $name';
  }

  @override
  String contactRequestedAt(Object date) {
    return 'கோரிய நாள்: $date';
  }

  @override
  String get actionApprove => 'ஒப்புதல் அளி';

  @override
  String get contactNoReceived => 'கோரிக்கைகள் எதுவும் வரவில்லை.';

  @override
  String get contactSentHeader => 'அனுப்பியவை (பதிலுக்காகக் காத்திருக்கிறது)';

  @override
  String contactTo(Object name) {
    return 'பெறுநர்: $name';
  }

  @override
  String get contactNoSent => 'நீங்கள் கோரிக்கைகள் எதுவும் அனுப்பவில்லை.';

  @override
  String profileAgePlace(int age, String place) {
    return '$age வயது · $place';
  }

  @override
  String get interestsTitle => 'விருப்பங்கள்';

  @override
  String get interestsTabReceived => 'பெற்றவை';

  @override
  String get interestsTabSent => 'அனுப்பியவை';

  @override
  String get interestsLoadingReceived =>
      'உங்களுக்கு வந்த விருப்பங்களை ஏற்றுகிறது…';

  @override
  String get interestsLoadingSent =>
      'நீங்கள் அனுப்பிய விருப்பங்களை ஏற்றுகிறது…';

  @override
  String get interestsReceivedEmptyTitle =>
      'இதுவரை விருப்பங்கள் எதுவும் வரவில்லை';

  @override
  String get interestsReceivedEmptySubtitle =>
      'உங்கள் சுயவிவரத்தில் யாரேனும் விருப்பம் தெரிவித்தால், அவர்கள் இங்கே தோன்றுவார்கள்.';

  @override
  String get interestsSentEmptyTitle => 'இதுவரை நீங்கள் விருப்பம் அனுப்பவில்லை';

  @override
  String get interestsSentEmptySubtitle =>
      'சுயவிவரங்களைப் பார்த்து, விருப்பம் அனுப்பி உறவைத் தொடங்குங்கள்.';

  @override
  String profileAgeCity(int age, String city) {
    return '$age வயது • $city';
  }

  @override
  String get profileNoAbout => 'தகவல் எதுவும் வழங்கப்படவில்லை';

  @override
  String interestAccepted(Object name) {
    return '$name அவர்களின் விருப்பத்தை ஏற்றுக்கொண்டீர்கள்';
  }

  @override
  String get interestAcceptFailed =>
      'இந்த விருப்பத்தை ஏற்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String interestDeclined(Object name) {
    return '$name அவர்களின் விருப்பத்தை மறுத்துவிட்டீர்கள்';
  }

  @override
  String get interestDeclineFailed =>
      'இந்த விருப்பத்தை மறுக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String ageYearsLong(int age) {
    return '$age வயது';
  }

  @override
  String get actionShortlist => 'விருப்பப் பட்டியலில் சேர்';

  @override
  String get actionShortlisted => 'விருப்பப் பட்டியலில் உள்ளது';

  @override
  String get actionReject => 'மறு';

  @override
  String get actionSendInterest => 'விருப்பம் அனுப்பு';

  @override
  String get actionInterestSent => 'விருப்பம் அனுப்பப்பட்டது';

  @override
  String get badgeVerified => 'சரிபார்க்கப்பட்ட சுயவிவரம்';

  @override
  String get badgeShortlisted => 'உங்கள் விருப்பப் பட்டியலில் உள்ளது';

  @override
  String placeDistrictState(Object district, Object state) {
    return '$district, $state';
  }

  @override
  String profileAgeHeight(int age, String height) {
    return '$age வயது, $height';
  }

  @override
  String get whyMatchedTooltip => 'இந்த வரன் ஏன் பொருத்தம்';

  @override
  String get actionInterest => 'விருப்பம்';

  @override
  String get actionAddToShortlist => 'விருப்பப் பட்டியலில் சேர்';

  @override
  String get actionRemoveFromShortlist => 'விருப்பப் பட்டியலிலிருந்து நீக்கு';

  @override
  String whyMatchNearby(Object district) {
    return 'நீங்கள் $district அருகில் வசிக்கிறீர்கள்';
  }

  @override
  String whyMatchEducation(Object education) {
    return 'ஒத்த கல்வித் தகுதி: $education';
  }

  @override
  String whyMatchCaste(Object caste) {
    return 'சாதி விருப்பம் பொருந்துகிறது: $caste';
  }

  @override
  String whyMatchLanguages(Object languages) {
    return 'பொதுவான மொழிகள்: $languages';
  }

  @override
  String get whyMatchGeneral =>
      'உங்கள் விருப்பங்களின் அடிப்படையில் நல்ல பொருத்தம்';

  @override
  String get maintenanceTitle => 'பராமரிப்புப் பணி நடைபெறுகிறது';

  @override
  String get maintenanceDefaultMessage =>
      'சேவையை மேம்படுத்திக்கொண்டிருக்கிறோம். சிறிது நேரம் கழித்து மீண்டும் வாருங்கள்.';

  @override
  String get helpTitle => 'உதவி & ஆதரவு';

  @override
  String get helpIntro =>
      'உங்கள் கணக்கு, சுயவிவரம் அல்லது கட்டணம் தொடர்பாக உதவி வேண்டுமா? எங்கள் ஆதரவுக் குழுவைத் தொடர்புகொள்ளுங்கள்.';

  @override
  String get helpNoContacts =>
      'ஆதரவுத் தொடர்பு விவரங்கள் தற்போது கிடைக்கவில்லை.';

  @override
  String get helpEmail => 'மின்னஞ்சல்';

  @override
  String get helpPhone => 'தொலைபேசி';

  @override
  String get helpWhatsapp => 'WhatsApp';

  @override
  String get helpCopy => 'நகலெடு';

  @override
  String helpCopied(Object label) {
    return '$label நகலெடுக்கப்பட்டது';
  }

  @override
  String get contactRevealUnavailable =>
      'தொடர்பு விவரங்களைப் பார்க்கும் வசதி தற்போது கிடைக்கவில்லை.';

  @override
  String get sectionBasicInfo => 'அடிப்படைத் தகவல்கள்';

  @override
  String get sectionAboutMe => 'என்னைப் பற்றி';

  @override
  String get sectionFamilyInfo => 'குடும்பத் தகவல்கள்';

  @override
  String get sectionPartnerPreferences =>
      'வாழ்க்கைத் துணை குறித்த எதிர்பார்ப்புகள்';

  @override
  String get sectionSimilarProfiles => 'இதே போன்ற சுயவிவரங்கள்';

  @override
  String get fieldReligion => 'மதம்';

  @override
  String get fieldCaste => 'சாதி';

  @override
  String get fieldSubCaste => 'உட்பிரிவு';

  @override
  String get fieldEducation => 'கல்வி';

  @override
  String get fieldOccupation => 'தொழில்';

  @override
  String get fieldWorkingLocation => 'பணிபுரியும் இடம்';

  @override
  String get fieldAnnualIncome => 'ஆண்டு வருமானம்';

  @override
  String get fieldHeight => 'உயரம்';

  @override
  String get fieldWeight => 'எடை';

  @override
  String get fieldMaritalStatus => 'திருமண நிலை';

  @override
  String get fieldLanguages => 'மொழிகள்';

  @override
  String get fieldHobbies => 'பொழுதுபோக்குகள்';

  @override
  String get fieldFatherName => 'தந்தையின் பெயர்';

  @override
  String get fieldFatherOccupation => 'தந்தையின் தொழில்';

  @override
  String get fieldMotherName => 'தாயின் பெயர்';

  @override
  String get fieldMotherOccupation => 'தாயின் தொழில்';

  @override
  String get fieldBrothers => 'சகோதரர்கள்';

  @override
  String get fieldSisters => 'சகோதரிகள்';

  @override
  String get fieldFamilyType => 'குடும்ப வகை';

  @override
  String get fieldFamilyValues => 'குடும்ப விழுமியங்கள்';

  @override
  String get fieldFamilyStatus => 'குடும்ப நிலை';

  @override
  String get fieldPreferredAge => 'விரும்பும் வயது';

  @override
  String get fieldPreferredHeight => 'விரும்பும் உயரம்';

  @override
  String get fieldPreferredStates => 'விரும்பும் மாநிலங்கள்';

  @override
  String get fieldPreferredCastes => 'விரும்பும் சாதிகள்';

  @override
  String get fieldPreferredEducation => 'விரும்பும் கல்வித் தகுதி';

  @override
  String get fieldPreferredOccupation => 'விரும்பும் தொழில்';

  @override
  String get fieldPreferredIncome => 'விரும்பும் வருமானம்';

  @override
  String get fieldOtherPreferences => 'பிற எதிர்பார்ப்புகள்';

  @override
  String get actionMessage => 'செய்தி அனுப்பு';

  @override
  String get actionRevealContact => 'தொடர்பு விவரம் பார் / கோரு';

  @override
  String get pleaseSignIn => 'முதலில் உள்நுழையவும்';

  @override
  String get blockedNoReveal =>
      'தடுக்கப்பட்ட சுயவிவரத்தின் தொடர்பு விவரங்களைப் பார்க்க இயலாது';

  @override
  String get contactRequestPending => 'தொடர்புக் கோரிக்கை நிலுவையில் உள்ளது';

  @override
  String get signInToMessage => 'செய்தி அனுப்ப உள்நுழையவும்';

  @override
  String get profileInactiveTitle => 'சுயவிவரம் செயலில் இல்லை';

  @override
  String get profileInactiveReactivatePrompt =>
      'உங்கள் சுயவிவரம் செயலிழக்கப்பட்டுள்ளது. செய்திகள் அனுப்ப இப்போதே மீண்டும் செயல்படுத்தவா?';

  @override
  String get actionNotNow => 'இப்போது வேண்டாம்';

  @override
  String get actionReactivate => 'மீண்டும் செயல்படுத்து';

  @override
  String get profileReactivated => 'சுயவிவரம் மீண்டும் செயல்படுத்தப்பட்டது';

  @override
  String get profileReactivateFailed =>
      'உங்கள் சுயவிவரத்தை மீண்டும் செயல்படுத்த முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get messagingDisabledInactive =>
      'இந்தச் சுயவிவரம் செயலில் இல்லை. தற்போது செய்தி அனுப்ப இயலாது.';

  @override
  String get messagingDisabledBlocked =>
      'தடுக்கப்பட்ட சுயவிவரங்களுக்குச் செய்தி அனுப்ப இயலாது';

  @override
  String get contactRequestSent => 'தொடர்புக் கோரிக்கை அனுப்பப்பட்டது';

  @override
  String get contactRequestFailed =>
      'கோரிக்கையை அனுப்ப முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get acceptContactTitle => 'தொடர்புக் கோரிக்கையை ஏற்கவா?';

  @override
  String acceptContactBody(Object name) {
    return '$name அவர்களுடன் தொடர்பு விவரங்களைப் பகிரவா?';
  }

  @override
  String get commonNo => 'இல்லை';

  @override
  String get contactRequestAccepted => 'தொடர்புக் கோரிக்கை ஏற்கப்பட்டது';

  @override
  String get contactAcceptFailed =>
      'கோரிக்கையை ஏற்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String interestSentTo(Object name) {
    return '$name அவர்களுக்கு விருப்பம் அனுப்பப்பட்டது';
  }

  @override
  String get interestSendFailed =>
      'உங்கள் விருப்பத்தை அனுப்ப முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get shortlistRemoved => 'விருப்பப் பட்டியலிலிருந்து நீக்கப்பட்டது';

  @override
  String get shortlistAdded => 'விருப்பப் பட்டியலில் சேர்க்கப்பட்டது';

  @override
  String get shortlistFailed =>
      'விருப்பப் பட்டியலைப் புதுப்பிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get contactDetailsTitle => 'தொடர்பு விவரங்கள்';

  @override
  String get contactNoPhone =>
      'இந்த உறுப்பினர் இன்னும் தொலைபேசி எண்ணைச் சேர்க்கவில்லை.';

  @override
  String contactPhone(Object number) {
    return 'தொலைபேசி: $number';
  }

  @override
  String contactWhatsapp(Object number) {
    return 'WhatsApp: $number';
  }

  @override
  String get contactLimitUpgrade =>
      'உங்கள் திட்டத்தின் தொடர்பு விவர வரம்பை எட்டிவிட்டீர்கள். மேலும் பார்க்க உங்கள் திட்டத்தை மேம்படுத்துங்கள்.';

  @override
  String get contactRevealFailed =>
      'தொடர்பு விவரங்களைக் காட்ட முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String messageTo(Object name) {
    return '$name அவர்களுக்குச் செய்தி';
  }

  @override
  String get messageHintLong => 'உங்கள் செய்தியைத் தட்டச்சு செய்யவும்…';

  @override
  String get messageSent => 'செய்தி அனுப்பப்பட்டது';

  @override
  String get messageSendFailed =>
      'உங்கள் செய்தியை அனுப்ப முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get blockProfileAction => 'சுயவிவரத்தைத் தடு';

  @override
  String get reportProfileAction => 'சுயவிவரத்தைப் புகாரளி';

  @override
  String get blockProfileTitle => 'சுயவிவரத்தைத் தடுக்கவா?';

  @override
  String blockProfileBody(Object name) {
    return 'இனி $name அவர்களை நீங்கள் பார்க்க மாட்டீர்கள்; அவர்களாலும் உங்களைத் தொடர்புகொள்ள இயலாது.';
  }

  @override
  String get profileBlocked => 'சுயவிவரம் தடுக்கப்பட்டது';

  @override
  String get blockFailed =>
      'இந்தச் சுயவிவரத்தைத் தடுக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get actionBlock => 'தடு';

  @override
  String get reportProfileTitle => 'சுயவிவரத்தைப் புகாரளி';

  @override
  String get reportReason => 'காரணம்';

  @override
  String get reportDetails => 'விவரங்கள் (விருப்பத்தேர்வு)';

  @override
  String get reportSubmitted =>
      'புகார் சமர்ப்பிக்கப்பட்டது. சமூகத்தைப் பாதுகாப்பாக வைக்க உதவியதற்கு நன்றி.';

  @override
  String get reportFailed =>
      'உங்கள் புகாரைச் சமர்ப்பிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get actionSubmit => 'சமர்ப்பி';

  @override
  String get similarEmpty => 'இதே போன்ற சுயவிவரங்கள் இதுவரை கிடைக்கவில்லை.';

  @override
  String get moreOptions => 'மேலும் விருப்பங்கள்';

  @override
  String get previousPhoto => 'முந்தைய புகைப்படம்';

  @override
  String get nextPhoto => 'அடுத்த புகைப்படம்';

  @override
  String photoCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String ageYearsOld(int age) {
    return '$age வயது';
  }

  @override
  String incomeLpa(String amount) {
    return 'ஆண்டுக்கு ₹$amount லட்சம்';
  }

  @override
  String weightKg(String weight) {
    return '$weight கி.கி.';
  }

  @override
  String ageRange(int min, int max) {
    return '$min - $max வயது';
  }

  @override
  String heightRangeCm(String min, String max) {
    return '$min - $max செ.மீ.';
  }

  @override
  String incomeRangeLpa(String min, String max) {
    return 'ஆண்டுக்கு ₹$min - $max லட்சம்';
  }

  @override
  String get noLimit => 'வரம்பு இல்லை';

  @override
  String ageCityShort(int age, String city) {
    return '$age • $city';
  }

  @override
  String get homeSubtitle =>
      'உங்கள் வாழ்க்கைத் துணைத் தேர்வுக்கு TryMeYourPartner';

  @override
  String get statMatches => 'வரன்கள்';

  @override
  String get statShortlisted => 'விருப்பப் பட்டியல்';

  @override
  String get statViewedYou => 'உங்களைப் பார்த்தவர்கள்';

  @override
  String get greetingMorning => 'காலை வணக்கம்';

  @override
  String get greetingAfternoon => 'மதிய வணக்கம்';

  @override
  String get greetingEvening => 'மாலை வணக்கம்';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get homeTopPicks => 'உங்களுக்கான சிறந்த தேர்வுகள்';

  @override
  String get homeYourMatches => 'உங்கள் வரன்கள்';

  @override
  String get homeViewedYou => 'உங்களைப் பார்த்தவர்கள்';

  @override
  String get homeNewThisWeek => 'இந்த வாரப் புதியவர்கள்';

  @override
  String get homeViewedByYou => 'நீங்கள் பார்த்தவர்கள்';

  @override
  String get homeSeeAll => 'அனைத்தும் பார்';

  @override
  String get homeEmptyTopPicks =>
      'இன்னும் சிறந்த தேர்வுகள் இல்லை. மிகப் பொருத்தமான சுயவிவரங்கள் இங்கே தோன்றும்.';

  @override
  String get homeEmptyMatches =>
      'இன்னும் வரன்கள் இல்லை. உங்கள் எதிர்பார்ப்புகளைப் புதுப்பிக்கவும் அல்லது தேடிப் பாருங்கள்.';

  @override
  String get homeEmptyViewedYou =>
      'இதுவரை யாரும் உங்கள் சுயவிவரத்தைப் பார்க்கவில்லை.';

  @override
  String get homeEmptyNewThisWeek =>
      'கடந்த 7 நாட்களில் புதிய சுயவிவரங்கள் இல்லை.';

  @override
  String get homeEmptyViewedByYou =>
      'சுயவிவரங்களைப் பார்க்கத் தொடங்குங்கள்; அவை இங்கே தோன்றும்.';

  @override
  String get homeCompleteProfileTitle =>
      'உங்கள் சுயவிவரத்தை நிறைவு செய்யுங்கள்';

  @override
  String homeCompleteProfileProgress(int percent) {
    return '$percent% நிறைவு · முழு விவரங்களுடன் மேலும் பொருத்தமான வரன்களைப் பெறுங்கள்';
  }

  @override
  String get homeCompleteAction => 'நிறைவு செய்';

  @override
  String get homeDeactivatedTitle => 'உங்கள் சுயவிவரம் செயலிழக்கப்பட்டுள்ளது';

  @override
  String get homeDeactivatedBody =>
      'செய்திகள் அனுப்பவும் பெறவும், தேடல்களில் தோன்றவும் உங்கள் சுயவிவரத்தை மீண்டும் செயல்படுத்துங்கள்.';

  @override
  String statLabel(String label, int count) {
    return '$label: $count';
  }

  @override
  String get matchesTabMatches => 'வரன்கள்';

  @override
  String get matchesTabTopPicks => 'சிறந்த தேர்வுகள்';

  @override
  String get matchesTabInterests => 'விருப்பங்கள்';

  @override
  String get matchesTabShortlistedByYou => 'நீங்கள் தேர்ந்தெடுத்தவர்கள்';

  @override
  String get matchesTabShortlistedYou => 'உங்களைத் தேர்ந்தெடுத்தவர்கள்';

  @override
  String get matchesTabViewed => 'பார்த்தவை';

  @override
  String get matchesTabViewedYou => 'உங்களைப் பார்த்தவர்கள்';

  @override
  String get matchesTabAccepted => 'ஏற்கப்பட்டவை';

  @override
  String get matchesChooseList => 'பட்டியலைத் தேர்ந்தெடு';

  @override
  String get matchesPreviousList => 'முந்தைய பட்டியல்';

  @override
  String get matchesNextList => 'அடுத்த பட்டியல்';

  @override
  String get signInRequiredTitle => 'உள்நுழைவு தேவை';

  @override
  String get signInRequiredBody =>
      'உங்களுக்கான வரனைக் கண்டறிந்து பொருத்தமான சுயவிவரங்களுடன் இணைய உள்நுழையவும்';

  @override
  String get matchesEmptyTitle => 'இன்னும் வரன்கள் இல்லை';

  @override
  String get matchesEmptyBody =>
      'மேலும் பொருத்தமான வரன்களைப் பெற உங்கள் சுயவிவரத்தை நிறைவு செய்யுங்கள்';

  @override
  String get actionCompleteProfile => 'சுயவிவரத்தை நிறைவு செய்';

  @override
  String get interestsNoneReceivedTitle => 'விருப்பங்கள் எதுவும் வரவில்லை';

  @override
  String get interestsNoneReceivedBody =>
      'பொருத்தமான வரன்களிடமிருந்து உங்களுக்கு விருப்பங்கள் வரும்';

  @override
  String get actionImproveProfile => 'சுயவிவரத்தை மேம்படுத்து';

  @override
  String get topPicksEmptyTitle => 'இன்னும் சிறந்த தேர்வுகள் இல்லை';

  @override
  String get topPicksEmptyBody =>
      'வரன்கள் கிடைத்ததும் மிகப் பொருத்தமான சுயவிவரங்கள் இங்கே தோன்றும்';

  @override
  String get actionRefreshMatches => 'வரன்களைப் புதுப்பி';

  @override
  String get shortlistEmptyTitle => 'விருப்பப் பட்டியலில் சுயவிவரங்கள் இல்லை';

  @override
  String get shortlistEmptyBody =>
      'சுயவிவரங்களைப் பார்த்து, பிடித்தவற்றை விருப்பப் பட்டியலில் சேருங்கள்';

  @override
  String get actionBrowseProfiles => 'சுயவிவரங்களைப் பார்';

  @override
  String get shortlistedYouEmptyTitle =>
      'இதுவரை யாரும் உங்களைத் தேர்ந்தெடுக்கவில்லை';

  @override
  String get shortlistedYouEmptyBody =>
      'மேலும் பலர் உங்கள் சுயவிவரத்தைக் காணும்போது, அவர்கள் இங்கே தோன்றுவார்கள்';

  @override
  String get viewedEmptyTitle => 'பார்த்த சுயவிவரங்கள் இல்லை';

  @override
  String get viewedEmptyBody =>
      'சுயவிவரங்களைப் பார்க்கத் தொடங்குங்கள்; அவை இங்கே தோன்றும்';

  @override
  String get viewedYouEmptyTitle => 'இன்னும் யாரும் பார்க்கவில்லை';

  @override
  String get viewedYouEmptyBody =>
      'உங்கள் சுயவிவரத்தைப் பார்ப்பவர்கள் இங்கே தோன்றுவார்கள்';

  @override
  String get actionRefresh => 'புதுப்பி';

  @override
  String get acceptedNoneTitle => 'ஏற்கப்பட்ட இணைப்புகள் இல்லை';

  @override
  String get acceptedNoneBody => 'ஏற்கப்பட்ட விருப்பங்கள் இங்கே தோன்றும்';

  @override
  String get matchesLoading => 'வரன்களை ஏற்றுகிறது…';

  @override
  String get errorTitle => 'ஏதோ தவறு நடந்துவிட்டது';

  @override
  String get errorLoadMatches =>
      'உங்கள் வரன்களை ஏற்ற முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String interestAcceptedFrom(Object name) {
    return '$name அவர்களின் விருப்பத்தை ஏற்றுக்கொண்டீர்கள்';
  }

  @override
  String interestRejectedFrom(Object name) {
    return '$name அவர்களின் விருப்பத்தை மறுத்துவிட்டீர்கள்';
  }

  @override
  String get restartToSignIn => 'உள்நுழைய, செயலியை மீண்டும் தொடங்கவும்.';

  @override
  String get religionHindu => 'இந்து';

  @override
  String get religionMuslim => 'இஸ்லாம்';

  @override
  String get religionChristian => 'கிறிஸ்தவம்';

  @override
  String get religionSikh => 'சீக்கியம்';

  @override
  String get religionJain => 'சமணம்';

  @override
  String get religionBuddhist => 'பௌத்தம்';

  @override
  String get optionOther => 'மற்றவை';

  @override
  String get maritalNeverMarried => 'திருமணம் ஆகாதவர்';

  @override
  String get maritalDivorced => 'விவாகரத்தானவர்';

  @override
  String get maritalWidowed => 'துணையை இழந்தவர்';

  @override
  String get maritalSeparated => 'பிரிந்து வாழ்பவர்';

  @override
  String get genderMale => 'ஆண்';

  @override
  String get genderFemale => 'பெண்';

  @override
  String get createdBySelf => 'நானே';

  @override
  String get createdBySibling => 'உடன்பிறந்தவர்';

  @override
  String get createdByParents => 'பெற்றோர்';

  @override
  String get createdByGuardian => 'பாதுகாவலர்';

  @override
  String get workBusiness => 'சொந்தத் தொழில்';

  @override
  String get workSalaried => 'சம்பளப் பணி';

  @override
  String get workNotWorking => 'தற்போது பணியில் இல்லை';

  @override
  String get registrationProfileCreated => 'சுயவிவரம் உருவாக்கப்பட்டது';

  @override
  String get registrationSaveFailed =>
      'உங்கள் விவரங்களைச் சேமிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get registrationTitle => 'பதிவை நிறைவு செய்யுங்கள்';

  @override
  String get registrationEmailFromLogin => 'மின்னஞ்சல் (உள்நுழைவிலிருந்து)';

  @override
  String get fieldFullName => 'முழுப் பெயர்';

  @override
  String get validationNameRequired => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get fieldGender => 'பாலினம்';

  @override
  String get validationSelectGender => 'பாலினத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get fieldDateOfBirth => 'பிறந்த தேதி';

  @override
  String get validationSelectDob => 'உங்கள் பிறந்த தேதியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get fieldPhone => 'தொலைபேசி எண்';

  @override
  String get validationPhone => 'சரியான தொலைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get fieldWhatsapp => 'WhatsApp எண்';

  @override
  String get validationWhatsapp => 'சரியான WhatsApp எண்ணை உள்ளிடவும்';

  @override
  String get fieldProfileCreatedBy => 'சுயவிவரத்தை உருவாக்கியவர்';

  @override
  String get validationSelectOne => 'ஒன்றைத் தேர்ந்தெடுக்கவும்';

  @override
  String get fieldWorkStatus => 'பணி நிலை';

  @override
  String get fieldOccupationCategory => 'தொழில் வகை';

  @override
  String get fieldQualification => 'கல்வித் தகுதி';

  @override
  String get fieldDiscipline => 'துறை';

  @override
  String get actionAdd => 'சேர்';

  @override
  String get fieldCity => 'நகரம்';

  @override
  String get validationReligion => 'மதத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get validationCaste => 'சாதியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get fieldSubCasteOptional => 'உட்பிரிவு (விருப்பத்தேர்வு)';

  @override
  String get fieldState => 'மாநிலம்';

  @override
  String get validationState => 'மாநிலத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get fieldDistrict => 'மாவட்டம்';

  @override
  String get validationDistrict => 'மாவட்டத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get actionSaveAndContinue => 'சேமித்துத் தொடரவும்';

  @override
  String get registrationLanguageHint =>
      'உங்களுக்கு வசதியான மொழியைத் தேர்ந்தெடுங்கள்';

  @override
  String get settingsAppearance => 'தோற்றம்';

  @override
  String get themeSystem => 'சாதன அமைப்பு';

  @override
  String get themeLight => 'வெளிர்';

  @override
  String get themeDark => 'இருள்';

  @override
  String get profileTitle => 'சுயவிவரம்';

  @override
  String get profileLoading => 'சுயவிவரத்தை ஏற்றுகிறது…';

  @override
  String get profileSignInBody =>
      'உங்கள் சுயவிவரம், விருப்பங்கள் மற்றும் உங்களுக்கான பரிந்துரைகளைப் பார்க்க உள்நுழையவும்';

  @override
  String planLabel(Object plan) {
    return 'திட்டம்: $plan';
  }

  @override
  String get planFree => 'இலவசம்';

  @override
  String get planGold => 'கோல்டு';

  @override
  String get planPlatinum => 'பிளாட்டினம்';

  @override
  String get upgradeComingSoon => 'திட்ட மேம்படுத்தல் இன்னும் கிடைக்கவில்லை.';

  @override
  String get actionUpgrade => 'மேம்படுத்து';

  @override
  String get emailVerificationTitle => 'மின்னஞ்சல் சரிபார்ப்பு தேவை';

  @override
  String get emailVerificationBody =>
      'உங்கள் கணக்கு அமைப்பை நிறைவு செய்ய, மின்னஞ்சலில் உள்ள சரிபார்ப்பு இணைப்பைத் திறக்கவும்.';

  @override
  String get actionResend => 'மீண்டும் அனுப்பு';

  @override
  String get changePhoto => 'சுயவிவரப் புகைப்படத்தை மாற்று';

  @override
  String memberSince(Object date) {
    return '$date முதல் உறுப்பினர்';
  }

  @override
  String get actionEditProfile => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get actionManagePhotos => 'புகைப்படங்களை நிர்வகி';

  @override
  String get statComplete => 'நிறைவு';

  @override
  String get statIncomplete => 'முழுமையில்லை';

  @override
  String get quickActionsTitle => 'விரைவுச் செயல்கள்';

  @override
  String get quickFavorites => 'எனது விருப்பங்கள்';

  @override
  String get quickFavoritesSub => 'உங்கள் விருப்பங்களைப் பாருங்கள்';

  @override
  String get quickMatchesSub => 'உங்கள் வரன்களைப் பாருங்கள்';

  @override
  String get quickCompletion => 'சுயவிவர நிறைவு';

  @override
  String get quickCompletionSub => 'உங்கள் சுயவிவரத்தை நிறைவு செய்யுங்கள்';

  @override
  String get quickRefresh => 'தரவைப் புதுப்பி';

  @override
  String get quickRefreshSub =>
      'உங்கள் சுயவிவரத்தையும் பரிந்துரைகளையும் மீண்டும் ஏற்று';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get settingsNotifications => 'அறிவிப்புகள்';

  @override
  String get settingsNotificationsSub =>
      'அறிவிப்பு விருப்பங்களை நிர்வகிக்கவும்';

  @override
  String get settingsPrivacy => 'தனியுரிமை & பாதுகாப்பு';

  @override
  String get settingsPrivacySub => 'கணக்குப் பாதுகாப்பு அமைப்புகள்';

  @override
  String get settingsHelpSub => 'உதவி பெறுங்கள், எங்களைத் தொடர்புகொள்ளுங்கள்';

  @override
  String get settingsAbout => 'செயலி பற்றி';

  @override
  String get settingsAboutSub => 'செயலியின் பதிப்பு மற்றும் தகவல்';

  @override
  String get actionSignOut => 'வெளியேறு';

  @override
  String get verificationEmailSent =>
      'சரிபார்ப்பு மின்னஞ்சல் அனுப்பப்பட்டது. உங்கள் இன்பாக்ஸைப் பாருங்கள்.';

  @override
  String get verificationEmailFailed =>
      'சரிபார்ப்பு மின்னஞ்சலை அனுப்ப முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get photoTake => 'புகைப்படம் எடு';

  @override
  String get photoGallery => 'கேலரியிலிருந்து தேர்ந்தெடு';

  @override
  String get photoAdd => 'புகைப்படம் சேர்';

  @override
  String get photoRemove => 'புகைப்படத்தை நீக்கு';

  @override
  String get photoPrimary => 'முதன்மை';

  @override
  String get photoMakePrimary => 'முதன்மையாக்கு';

  @override
  String get accountActions => 'கணக்குச் செயல்கள்';

  @override
  String get actionReactivateProfile => 'சுயவிவரத்தை மீண்டும் செயல்படுத்து';

  @override
  String get actionDeactivateProfile => 'சுயவிவரத்தைச் செயலிழக்கச் செய்';

  @override
  String get actionDeleteProfile => 'சுயவிவரத்தை நீக்கு';

  @override
  String get profileNotLoaded =>
      'உங்கள் சுயவிவரம் இன்னும் ஏற்றப்படவில்லை. மீண்டும் முயலவும்.';

  @override
  String get deactivateBody =>
      'செயலிழக்கச் செய்தால் உங்கள் சுயவிவரம் தேடல்களில் தெரியாது; உங்களுக்குச் செய்திகளும் வராது. சுயவிவரத்தைத் திருத்துவதன் மூலம் எப்போது வேண்டுமானாலும் மீண்டும் செயல்படுத்தலாம்.';

  @override
  String get actionDeactivate => 'செயலிழக்கச் செய்';

  @override
  String get profileDeactivated => 'சுயவிவரம் செயலிழக்கப்பட்டது';

  @override
  String get profileDeactivateFailed =>
      'உங்கள் சுயவிவரத்தைச் செயலிழக்கச் செய்ய முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get deleteBody =>
      'சுயவிவரத்தை நீக்கினால் உங்கள் சுயவிவரப் பதிவுகள் நிரந்தரமாக அகற்றப்படும். தேவைப்பட்டால் ஆதரவுக் குழு மீட்டெடுக்க, குறைந்தபட்சக் காப்பகம் மட்டும் வைக்கப்படும். இதைத் திரும்பப் பெற இயலாது.';

  @override
  String get actionDelete => 'நீக்கு';

  @override
  String get profileDeleted =>
      'சுயவிவரம் நீக்கப்பட்டது. உங்களை வெளியேற்றுகிறோம்…';

  @override
  String get profileDeleteFailed =>
      'உங்கள் சுயவிவரத்தை நீக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get signOutConfirm => 'நிச்சயமாக வெளியேற விரும்புகிறீர்களா?';

  @override
  String get signingOut => 'வெளியேறுகிறது…';

  @override
  String get interestsShownHere =>
      'உங்கள் விருப்பங்கள் \"விருப்பங்கள்\" தாவலில் உள்ளன.';

  @override
  String get matchesInTab => 'உங்கள் வரன்கள் \"வரன்கள்\" தாவலில் உள்ளன.';

  @override
  String get notificationSettingsComingSoon =>
      'அறிவிப்பு அமைப்புகள் இன்னும் கிடைக்கவில்லை.';

  @override
  String get securitySettingsComingSoon =>
      'பாதுகாப்பு அமைப்புகள் இன்னும் கிடைக்கவில்லை.';

  @override
  String get aboutComingSoon => '\"செயலி பற்றி\" பக்கம் இன்னும் கிடைக்கவில்லை.';

  @override
  String get profileStatusActive => 'உங்கள் சுயவிவரம் செயலில் உள்ளது';

  @override
  String get profileStatusDeactivated =>
      'உங்கள் சுயவிவரம் செயலிழக்கப்பட்டுள்ளது';

  @override
  String get profileStatusMissing =>
      'சுயவிவரம் இல்லை. வரன்களைப் பெற உங்கள் சுயவிவரத்தை உருவாக்குங்கள்.';

  @override
  String get noProfileTitle => 'சுயவிவரம் இல்லை';

  @override
  String get noProfileBody =>
      'உங்கள் கணக்குடன் இணைந்த சுயவிவரம் இல்லை. நீங்கள் பார்வையிடலாம்; ஆனால் உங்களுக்கான வரன்களைப் பெற, உங்கள் சுயவிவரத்தை உருவாக்குங்கள்.';

  @override
  String get createProfileFailed =>
      'உங்கள் சுயவிவரத்தை உருவாக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get actionCreateProfile => 'எனது சுயவிவரத்தை உருவாக்கு';

  @override
  String get profileRestored =>
      'காப்பகத்திலிருந்து சுயவிவரம் மீட்டெடுக்கப்பட்டது.';

  @override
  String get noArchivedProfile =>
      'மீட்டெடுக்கக் காப்பகச் சுயவிவரம் எதுவும் இல்லை.';

  @override
  String get restoreFailed =>
      'உங்கள் சுயவிவரத்தை மீட்டெடுக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get actionRestoreProfile => 'எனது சுயவிவரத்தை மீட்டெடு';

  @override
  String get diagnosticsPrinted =>
      'கண்டறிதல் விவரங்கள் console-இல் எழுதப்பட்டன';

  @override
  String get actionPrintDiagnostics => 'கண்டறிதல் விவரங்களை அச்சிடு';

  @override
  String get myProfileTitle => 'எனது சுயவிவரம்';

  @override
  String get fieldName => 'பெயர்';

  @override
  String get fieldAge => 'வயது';

  @override
  String get fieldLocation => 'இருப்பிடம்';

  @override
  String get actionEditMyProfile => 'எனது சுயவிவரத்தைத் திருத்து';

  @override
  String get refreshSuccess => 'சுயவிவரத் தரவு புதுப்பிக்கப்பட்டது';

  @override
  String get refreshNotSignedIn =>
      'புதுப்பிக்க இயலவில்லை: நீங்கள் உள்நுழையவில்லை';

  @override
  String get defaultUserName => 'உறுப்பினர்';

  @override
  String get statInterests => 'விருப்பங்கள்';

  @override
  String get searchTitle => 'சுயவிவரங்களைத் தேடு';

  @override
  String get savedSearchesTooltip => 'சேமித்த தேடல்கள்';

  @override
  String get contactRequestsTooltip => 'தொடர்புக் கோரிக்கைகள்';

  @override
  String get actionResetFilters => 'வடிகட்டிகளை மீட்டமை';

  @override
  String get searchTip =>
      'குறிப்பு: வடிகட்டிகளை மாற்றி, தேடு என்பதைத் தட்டினால் முடிவுகள் இங்கே தோன்றும்.';

  @override
  String get searchLocationPrefs => 'இருப்பிட விருப்பங்கள்';

  @override
  String get searchBasicPrefs => 'அடிப்படை விருப்பங்கள்';

  @override
  String get fieldSubCasteShort => 'உட்பிரிவு';

  @override
  String get searchMoreEducations => 'மேலும் கல்வித் தகுதிகள்';

  @override
  String get searchMoreOccupations => 'மேலும் தொழில்கள்';

  @override
  String get searchMoreCastes => 'மேலும் சாதிகள்';

  @override
  String get searchRangePrefs => 'வரம்பு விருப்பங்கள்';

  @override
  String get filterOnlineNow => 'இப்போது ஆன்லைனில்';

  @override
  String get filterRecentlyActive => 'சமீபத்தில் செயலில் இருந்தவர்கள்';

  @override
  String get sortBy => 'வரிசைப்படுத்து';

  @override
  String get sortNewest => 'புதியவர்கள் முதலில்';

  @override
  String get sortYoungerFirst => 'வயதில் இளையவர்கள் முதலில்';

  @override
  String get sortOlderFirst => 'வயதில் மூத்தவர்கள் முதலில்';

  @override
  String get sortHigherIncome => 'அதிக வருமானம் முதலில்';

  @override
  String get actionSaveSearch => 'இந்தத் தேடலைச் சேமி';

  @override
  String get quickSearch => 'விரைவுத் தேடல் (வடிகட்டிகள் இன்றி)';

  @override
  String get searchEmptyTitle => 'சுயவிவரங்களைத் தேடுங்கள்';

  @override
  String get searchEmptyBody =>
      'பொருத்தமான வரன்களைக் கண்டறிய மேலே உள்ள வடிகட்டிகளைப் பயன்படுத்துங்கள்';

  @override
  String get contactAvailable => 'தொடர்பு விவரம் கிடைக்கும்';

  @override
  String get contactStateRequestSent => 'கோரிக்கை அனுப்பப்பட்டது';

  @override
  String get contactStateRequestReceived => 'கோரிக்கை வந்துள்ளது';

  @override
  String get recentChip => 'சமீபத்தியவர்கள்';

  @override
  String get joinedWithinTooltip => 'சேர்ந்து எத்தனை நாட்கள்';

  @override
  String get actionClearAll => 'அனைத்தையும் அழி';

  @override
  String get completeRegistrationFirst => 'முதலில் பதிவை நிறைவு செய்யுங்கள்.';

  @override
  String get saveSearchTitle => 'இந்தத் தேடலைச் சேமி';

  @override
  String get saveSearchHint => 'எ.கா. சென்னை IT, 25-30, இந்து';

  @override
  String get savedSearchesEmpty => 'இதுவரை சேமித்த தேடல்கள் இல்லை.';

  @override
  String get deleteSavedSearchTitle => 'சேமித்த தேடலை நீக்கவா?';

  @override
  String get runSearch => 'தேடலை இயக்கு';

  @override
  String get fieldAbout => 'பற்றி';

  @override
  String get fieldLocationPlain => 'இருப்பிடம்';

  @override
  String get searchLoading => 'ஏற்றுகிறது…';

  @override
  String rangeAge(int min, int max) {
    return 'வயது: $min - $max';
  }

  @override
  String rangeHeight(int min, int max) {
    return 'உயரம்: $min - $max செ.மீ.';
  }

  @override
  String heightCm(int value) {
    return '$value செ.மீ.';
  }

  @override
  String rangeIncome(String min, String max) {
    return 'வருமானம்: ஆண்டுக்கு $min - $max லட்சம்';
  }

  @override
  String incomeLakhShort(String value) {
    return '$value லட்.';
  }

  @override
  String profilesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count சுயவிவரங்கள் கிடைத்தன',
      one: '1 சுயவிவரம் கிடைத்தது',
      zero: 'சுயவிவரங்கள் எதுவும் இல்லை',
    );
    return '$_temp0';
  }

  @override
  String profilesRecommended(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பரிந்துரைக்கப்பட்ட சுயவிவரங்கள்',
      one: '1 பரிந்துரைக்கப்பட்ட சுயவிவரம்',
    );
    return '$_temp0';
  }

  @override
  String chipLabelValue(Object label, Object value) {
    return '$label: $value';
  }

  @override
  String chipAgeRange(int min, int max) {
    return 'வயது $min-$max';
  }

  @override
  String chipHeightRange(int min, int max) {
    return 'உயரம் $min-$max செ.மீ.';
  }

  @override
  String chipIncomeRange(String min, String max) {
    return 'வருமானம் $min-$max லட்.';
  }

  @override
  String joinedWithinDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'சேர்ந்தது: கடந்த $days நாட்கள்',
      one: 'சேர்ந்தது: கடந்த 1 நாள்',
    );
    return '$_temp0';
  }

  @override
  String get searchFailed => 'தேடல் வெற்றிபெறவில்லை. மீண்டும் முயலவும்.';

  @override
  String get filtersLoadFailed =>
      'வடிகட்டி விருப்பங்களை ஏற்ற முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String defaultSearchName(Object date) {
    return 'தேடல் $date';
  }

  @override
  String savedSearchNamed(Object name) {
    return '\"$name\" தேடல் சேமிக்கப்பட்டது';
  }

  @override
  String get saveSearchFailed =>
      'இந்தத் தேடலைச் சேமிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String deleteSavedSearchBody(Object name) {
    return '\"$name\" நீக்கப்படும்.';
  }

  @override
  String savedSearchAlertsOn(Object date) {
    return 'அறிவிப்புகள் இயக்கத்தில் • $date';
  }

  @override
  String savedSearchAlertsOff(Object date) {
    return 'அறிவிப்புகள் நிறுத்தத்தில் • $date';
  }

  @override
  String get toggleFailed =>
      'இந்த அமைப்பை மாற்ற முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get langTamil => 'தமிழ்';

  @override
  String get langEnglish => 'ஆங்கிலம்';

  @override
  String get langTelugu => 'தெலுங்கு';

  @override
  String get langKannada => 'கன்னடம்';

  @override
  String get langMalayalam => 'மலையாளம்';

  @override
  String get langHindi => 'இந்தி';

  @override
  String get editSectionLocationCareer => 'இருப்பிடம் & பணி';

  @override
  String get editTabLocationCareer => 'இருப்பிடம் & பணி';

  @override
  String get editProfileTitle => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get editTabBasic => 'அடிப்படை';

  @override
  String get editTabContact => 'தொடர்பு';

  @override
  String get editTabFamily => 'குடும்பம்';

  @override
  String get editTabPartner => 'துணை எதிர்பார்ப்புகள்';

  @override
  String get editTabPhotos => 'புகைப்படங்கள்';

  @override
  String get profileLoadingYours => 'உங்கள் சுயவிவரத்தை ஏற்றுகிறது…';

  @override
  String get editEmailHelper =>
      'உங்கள் உள்நுழைவு மின்னஞ்சல். இதை நீங்கள் மட்டுமே பார்க்க முடியும்.';

  @override
  String get fieldDobRequired => 'பிறந்த தேதி *';

  @override
  String get fieldReligionRequired => 'மதம் *';

  @override
  String get fieldCasteRequired => 'சாதி *';

  @override
  String get fieldStateRequired => 'மாநிலம் *';

  @override
  String get fieldDistrictRequired => 'மாவட்டம் *';

  @override
  String get fieldEducationRequired => 'கல்வி *';

  @override
  String get fieldHeightCm => 'உயரம் (செ.மீ.)';

  @override
  String get fieldWeightKg => 'எடை (கி.கி.)';

  @override
  String get sectionContactInfo => 'தொடர்புத் தகவல்கள்';

  @override
  String get fieldPhoneShort => 'தொலைபேசி';

  @override
  String get fieldAltPhone => 'மாற்றுத் தொலைபேசி';

  @override
  String get fieldCurrentAddress => 'தற்போதைய முகவரி';

  @override
  String get fieldPermanentAddress => 'நிரந்தர முகவரி';

  @override
  String get showPhoneNumber => 'தொலைபேசி எண்ணைக் காட்டு';

  @override
  String get showAddress => 'முகவரியைக் காட்டு';

  @override
  String get fieldFamilyDetails => 'குடும்ப விவரங்கள்';

  @override
  String get fieldMinAge => 'குறைந்தபட்ச வயது';

  @override
  String get fieldMaxAge => 'அதிகபட்ச வயது';

  @override
  String get fieldMinHeight => 'குறைந்தபட்ச உயரம் (செ.மீ.)';

  @override
  String get fieldMaxHeight => 'அதிகபட்ச உயரம் (செ.மீ.)';

  @override
  String get fieldPreferredDistricts => 'விரும்பும் மாவட்டங்கள்';

  @override
  String get fieldPreferredOccupations => 'விரும்பும் தொழில்கள்';

  @override
  String get fieldMinIncome => 'குறைந்தபட்ச வருமானம்';

  @override
  String get fieldMaxIncome => 'அதிகபட்ச வருமானம்';

  @override
  String get fieldPreferredMaritalStatus => 'விரும்பும் திருமண நிலை';

  @override
  String get profilePhotosTitle => 'சுயவிவரப் புகைப்படங்கள்';

  @override
  String get actionPrevious => 'முந்தையது';

  @override
  String get profileSavedLoadingMatches =>
      'சுயவிவரம் சேமிக்கப்பட்டது. உங்கள் வரன்களை ஏற்றுகிறது…';

  @override
  String get fillMandatoryFields =>
      'தொடர, * குறியிட்ட அனைத்துப் புலங்களையும் நிரப்பவும்.';

  @override
  String get actionFinish => 'முடி';

  @override
  String get actionNext => 'அடுத்து';

  @override
  String get mandatoryBanner =>
      'பொருத்தமான வரன்களைக் காட்ட, * குறியிட்ட புலங்கள் அவசியம்.';

  @override
  String get selectDate => 'தேதியைத் தேர்ந்தெடு';

  @override
  String get chipsInputHint => 'தட்டச்சு செய்து + அழுத்திச் சேர்க்கவும்';

  @override
  String get actionEdit => 'திருத்து';

  @override
  String get savedBasic => 'அடிப்படைத் தகவல்கள் சேமிக்கப்பட்டன';

  @override
  String get savedBasicAuto => 'அடிப்படைத் தகவல்கள் தானாகச் சேமிக்கப்பட்டன';

  @override
  String get savedLocation => 'இருப்பிடம் & பணி விவரங்கள் சேமிக்கப்பட்டன';

  @override
  String get savedLocationAuto =>
      'இருப்பிடம் & பணி விவரங்கள் தானாகச் சேமிக்கப்பட்டன';

  @override
  String get savedContact => 'தொடர்புத் தகவல்கள் சேமிக்கப்பட்டன';

  @override
  String get savedContactAuto => 'தொடர்புத் தகவல்கள் தானாகச் சேமிக்கப்பட்டன';

  @override
  String get savedFamily => 'குடும்பத் தகவல்கள் சேமிக்கப்பட்டன';

  @override
  String get savedFamilyAuto => 'குடும்பத் தகவல்கள் தானாகச் சேமிக்கப்பட்டன';

  @override
  String get savedPartner => 'துணை எதிர்பார்ப்புகள் சேமிக்கப்பட்டன';

  @override
  String get savedPartnerAuto => 'துணை எதிர்பார்ப்புகள் தானாகச் சேமிக்கப்பட்டன';

  @override
  String get savedPhotos => 'புகைப்படங்கள் புதுப்பிக்கப்பட்டன';

  @override
  String get profileStillLoading =>
      'உங்கள் சுயவிவரம் இன்னும் ஏற்றப்படுகிறது. சிறிது நேரம் கழித்து மீண்டும் முயலவும்.';

  @override
  String get fillDobReligionCaste =>
      'உங்கள் பிறந்த தேதி, மதம், சாதி ஆகியவற்றை நிரப்பவும்';

  @override
  String get photosGuidance =>
      'தெளிவான 3 புகைப்படங்கள் வரை சேர்க்கலாம். முகம் தெரியும்படி செதுக்குங்கள். வடிகட்டிகளும் குழுப் புகைப்படங்களும் வேண்டாம்.';

  @override
  String get removePhotoTitle => 'புகைப்படத்தை நீக்கவா?';

  @override
  String get removePhotoBody =>
      'இந்தப் புகைப்படம் சேமிப்பகத்திலிருந்து நீக்கப்படும்.';

  @override
  String autoSavedPrefix(Object message) {
    return 'தானாகச் சேமிக்கப்பட்டது: $message';
  }

  @override
  String get autoSaveFailed =>
      'தானாகச் சேமிக்க முடியவில்லை. உங்கள் மாற்றங்கள் அப்படியே உள்ளன; மீண்டும் முயல சேமி என்பதைத் தட்டவும்.';

  @override
  String get saveFailed =>
      'உங்கள் மாற்றங்களைச் சேமிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String fieldRequired(Object field) {
    return '$field அவசியம்';
  }

  @override
  String photoSlot(int number) {
    return 'புகைப்படம் $number';
  }

  @override
  String get familyNuclear => 'தனிக் குடும்பம்';

  @override
  String get familyJoint => 'கூட்டுக் குடும்பம்';

  @override
  String get valuesTraditional => 'பாரம்பரியம்';

  @override
  String get valuesModern => 'நவீனம்';

  @override
  String get valuesModerate => 'மிதமானது';

  @override
  String get statusMiddleClass => 'நடுத்தர வர்க்கம்';

  @override
  String get statusUpperMiddleClass => 'உயர் நடுத்தர வர்க்கம்';

  @override
  String get statusRich => 'வசதியானவர்';

  @override
  String get toastInterestsUpdated => 'உங்கள் விருப்பங்கள் புதுப்பிக்கப்பட்டன';

  @override
  String get toastInterestWithdrawn => 'ஒரு விருப்பம் திரும்பப் பெறப்பட்டது';
}
