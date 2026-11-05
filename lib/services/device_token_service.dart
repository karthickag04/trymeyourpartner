/// Supabase-only mode: device token registration is disabled.
/// This no-op shim remains to avoid import errors from legacy references.
class DeviceTokenService {
  static Future<void> registerCurrentDeviceToken() async {}
}
