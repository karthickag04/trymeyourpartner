import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/backend/supabase_console_backend.dart';
import 'src/config.dart';
import 'src/screens/config_error_screen.dart';
import 'src/session/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.fromEnvironment();
  if (!config.isComplete) {
    runApp(const ConfigErrorApp());
    return;
  }
  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseKey,
  );
  final controller = SessionController(
    SupabaseConsoleBackend(Supabase.instance.client),
  )..start();
  runApp(AdminApp(controller: controller));
}
