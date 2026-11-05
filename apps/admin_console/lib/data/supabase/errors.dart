import 'package:supabase_flutter/supabase_flutter.dart';

import '../../src/services/console_exception.dart';

/// Runs [action] and turns Supabase errors into [ConsoleException].
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AuthException catch (e) {
    throw ConsoleException(e.message);
  } on PostgrestException catch (e) {
    throw ConsoleException(e.message);
  }
}
