import 'package:flutter/material.dart';

import 'data/supabase/supabase_bootstrap.dart';
import 'src/app.dart';
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
  final (auth, data) = await connectSupabase(config);
  final controller = SessionController(auth: auth, data: data)..start();
  runApp(AdminApp(controller: controller));
}
