import 'package:supabase_flutter/supabase_flutter.dart';

import '../../src/config.dart';
import '../../src/services/console_auth.dart';
import '../../src/services/console_data.dart';
import 'supabase_console_auth.dart';
import 'supabase_console_data.dart';

/// Connects to Supabase and returns the console's services.
Future<(ConsoleAuth, ConsoleData)> connectSupabase(AppConfig config) async {
  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseKey,
  );
  final client = Supabase.instance.client;
  return (SupabaseConsoleAuth(client), SupabaseConsoleData(client));
}
