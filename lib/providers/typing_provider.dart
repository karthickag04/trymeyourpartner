import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/typing_service.dart';

class TypingProvider extends ChangeNotifier {
  final TypingService _typing;
  final String myProfileId;
  final String otherProfileId;

  TypingProvider(this._typing, this.myProfileId, this.otherProfileId);

  Timer? _poll;
  bool _otherTyping = false;
  DateTime? _lastTypingSentAt;

  bool get isOtherTyping => _otherTyping;

  void start({Duration pollEvery = const Duration(seconds: 3)}) {
    _poll?.cancel();
    _poll = Timer.periodic(pollEvery, (_) async {
      try {
        final t = await _typing.isTyping(
          myProfileId: myProfileId,
          otherProfileId: otherProfileId,
        );
        if (t != _otherTyping) {
          _otherTyping = t;
          notifyListeners();
        }
      } catch (_) {
        // ignore
      }
    });
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
  }

  void onUserTyping({int ttlSeconds = 7}) {
    final now = DateTime.now();
    if (_lastTypingSentAt == null ||
        now.difference(_lastTypingSentAt!) > const Duration(seconds: 3)) {
      _lastTypingSentAt = now;
      try {
        _typing.sendTyping(
          myProfileId: myProfileId,
          otherProfileId: otherProfileId,
          ttlSeconds: ttlSeconds,
        );
      } catch (_) {
        // ignore
      }
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
