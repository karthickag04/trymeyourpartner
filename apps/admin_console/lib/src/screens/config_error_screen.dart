import 'package:flutter/material.dart';

/// Shown when the build is missing SUPABASE_KEY (see .env.example).
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This build has no Supabase settings. Build it with '
              '--dart-define-from-file=.env (see apps/admin_console/.env.example).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
