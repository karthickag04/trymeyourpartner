import 'package:flutter/foundation.dart';

/// Where errors that the app recovers from are reported, instead of being
/// dropped in an empty `catch`. Today they go to the debug log; crash
/// reporting (Sentry, P1-10) hooks in here so every site is covered at once.
///
/// Use it for best-effort work (presence, unread counts, remembered filters,
/// closing a channel). Anything the member asked to save must still fail
/// visibly: report, then rethrow.
typedef ErrorSink =
    void Function(Object error, StackTrace stack, {required String where});

ErrorSink errorSink = _debugLog;

void reportError(Object error, StackTrace stack, {required String where}) {
  errorSink(error, stack, where: where);
}

void _debugLog(Object error, StackTrace stack, {required String where}) {
  debugPrint('⚠️ [$where] $error');
}
