import 'package:http/http.dart' as http;
import '../core/services/auth_service.dart';
import '../core/services/profile_service.dart';
import '../core/services/matrimonial_domain_service.dart';
import '../core/services/realtime_service.dart';
import '../core/services/message_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/safety_service.dart';
import '../core/services/icebreaker_service.dart';
import '../core/services/saved_search_service.dart';
import '../core/services/contact_exchange_service.dart';
import '../core/services/presence_service.dart';
import '../core/services/typing_service.dart';
import '../core/services/photo_service.dart';
import '../data/photo/default_photo_service.dart';
import '../data/supabase/supabase_auth_service.dart';
import '../data/supabase/supabase_profile_service.dart';
import '../data/supabase/supabase_matrimonial_service.dart';
import '../data/supabase/supabase_realtime_service.dart';
import '../data/supabase/supabase_message_service.dart';
import '../data/supabase/supabase_notification_service.dart';
import '../data/supabase/supabase_storage_service.dart';
import '../data/supabase/supabase_safety_service.dart';
import '../data/supabase/supabase_icebreaker_service.dart';
import '../data/supabase/supabase_saved_search_service.dart';
import '../data/supabase/supabase_contact_exchange_service.dart';
import '../data/supabase/supabase_presence_service.dart';
import '../data/supabase/supabase_typing_service.dart';
import '../data/http/http_auth_service.dart';
import '../data/http/http_profile_service.dart';
import '../data/http/http_matrimonial_service.dart';
import '../data/http/http_realtime_service.dart';
import '../data/http/http_message_service.dart';
import '../data/http/http_notification_service.dart';
import '../data/http/http_client.dart';
import '../data/http/http_storage_service.dart';
import '../data/http/http_safety_service.dart';
import '../data/http/http_icebreaker_service.dart';
import '../data/http/http_saved_search_service.dart';
import '../data/http/http_contact_exchange_service.dart';
import '../data/http/http_presence_service.dart';
import '../data/http/http_typing_service.dart';

enum BackendMode { supabase, http }

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  BackendMode _mode = BackendMode.supabase;
  bool _configured = false;

  late AuthService authService;
  late ProfileService profileService;
  late MatrimonialDomainService matrimonialService;
  late RealtimeService realtimeService;
  late MessageService messageService;
  late NotificationService notificationService;
  late StorageService storageService;
  late SafetyService safetyService;
  late SavedSearchService savedSearchService;
  late IcebreakerService icebreakerService;
  late ContactExchangeService contactExchangeService;
  late PresenceService presenceService;
  late TypingService typingService;
  late PhotoService photoService;

  void configure({BackendMode? mode, String? apiBaseUrl}) {
    final desiredMode = mode ?? _parseBackendModeFromEnv();
    // If already configured with the same mode, do nothing (idempotent)
    if (_configured && desiredMode == _mode) {
      return;
    }
    _mode = desiredMode;

    switch (_mode) {
      case BackendMode.supabase:
        authService = SupabaseAuthService();
        profileService = SupabaseProfileService();
        matrimonialService = SupabaseMatrimonialDomainService();
        realtimeService = SupabaseRealtimeService();
        messageService = SupabaseMessageService();
        notificationService = SupabaseNotificationService();
        storageService = SupabaseStorageService();
        safetyService = SupabaseSafetyService();
        savedSearchService = SupabaseSavedSearchService();
        icebreakerService = SupabaseIcebreakerService();
        contactExchangeService = SupabaseContactExchangeService();
        presenceService = SupabasePresenceService();
        typingService = SupabaseTypingService();
        photoService = DefaultPhotoService();
        break;
      case BackendMode.http:
        final client = http.Client();
        final base =
            apiBaseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8080',
            );
        final httpAuth = HttpAuthService(client, baseUrl: base);
        authService = httpAuth;
        // Use a lightweight API client that injects auth token when available
        // Note: currentAccessToken may return null until login is implemented
        final api = ApiClient(
          client,
          baseUrl: base,
          getToken: () => authService.currentAccessToken(),
          onUnauthorized: () => httpAuth.tryRefresh(),
        );
        profileService = HttpProfileService(api);
        matrimonialService = HttpMatrimonialDomainService(api);
        realtimeService = HttpRealtimeService(api);
        messageService = HttpMessageService(api);
        notificationService = HttpNotificationService(api);
        storageService = HttpStorageService(api);
        safetyService = HttpSafetyService(api);
        savedSearchService = HttpSavedSearchService(api);
        icebreakerService = HttpIcebreakerService(api);
        contactExchangeService = HttpContactExchangeService(api);
        presenceService = HttpPresenceService(api);
        typingService = HttpTypingService(api);
        photoService = DefaultPhotoService();
        break;
    }
    _configured = true;
  }

  bool get isConfigured => _configured;

  BackendMode get backendMode => _mode;

  void ensureConfigured() {
    if (!_configured) configure();
  }

  BackendMode _parseBackendModeFromEnv() {
    const mode = String.fromEnvironment(
      'BACKEND_MODE',
      defaultValue: 'supabase',
    );
    return mode.toLowerCase() == 'http'
        ? BackendMode.http
        : BackendMode.supabase;
  }
}

final sl = ServiceLocator();
