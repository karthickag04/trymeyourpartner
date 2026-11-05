import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models.dart';
import '../services/console_auth.dart';
import '../services/console_data.dart';
import '../services/console_exception.dart';

enum SessionStage {
  /// Checking for an existing session.
  starting,

  signedOut,

  /// Signed in with a password but has no active staff account.
  notStaff,

  /// Staff member who must add an authenticator app.
  mfaEnrol,

  /// Staff member who must enter a code from their authenticator app.
  mfaVerify,

  /// MFA-verified staff member (aal2): the console is available.
  ready,
}

/// Drives sign-in: password, staff check, then TOTP enrolment or
/// verification. Staff pages are only reachable in [SessionStage.ready].
class SessionController extends ChangeNotifier {
  SessionController({required this.auth, required this.data}) {
    _signedOutSub = auth.signedOut.listen((_) {
      if (stage != SessionStage.signedOut && stage != SessionStage.notStaff) {
        _reset(SessionStage.signedOut);
      }
    });
  }

  final ConsoleAuth auth;
  final ConsoleData data;
  late final StreamSubscription<void> _signedOutSub;

  SessionStage stage = SessionStage.starting;
  StaffProfile? profile;
  TotpEnrolment? enrolment;
  String? _verifyFactorId;
  String? error;
  bool busy = false;

  String? get email => auth.email;

  Future<void> start() => _run(() async {
    if (auth.hasSession) {
      await _afterPassword();
    } else {
      stage = SessionStage.signedOut;
    }
  }, failStage: SessionStage.signedOut);

  Future<void> signIn(String email, String password) => _run(() async {
    await auth.signIn(email: email.trim(), password: password);
    await _afterPassword();
  }, failStage: SessionStage.signedOut);

  Future<void> verifyCode(String code) => _run(() async {
    final factorId = enrolment?.factorId ?? _verifyFactorId;
    if (factorId == null) {
      throw StateError('No authenticator to verify');
    }
    await auth.verifyTotp(factorId: factorId, code: code.trim());
    await _loadVerifiedProfile();
  });

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } finally {
      _reset(SessionStage.signedOut);
    }
  }

  /// From the refusal screen back to the sign-in form.
  void backToSignIn() => _reset(SessionStage.signedOut);

  Future<void> _afterPassword() async {
    final staff = await data.loadStaffProfile();
    if (staff == null) {
      await auth.signOut();
      _reset(SessionStage.notStaff);
      return;
    }
    profile = staff;
    final mfa = await auth.mfaStatus();
    if (mfa.sessionVerified) {
      await _loadVerifiedProfile();
    } else if (mfa.verifiedFactorId != null) {
      _verifyFactorId = mfa.verifiedFactorId;
      stage = SessionStage.mfaVerify;
    } else {
      enrolment = await auth.enrolTotp();
      stage = SessionStage.mfaEnrol;
    }
  }

  Future<void> _loadVerifiedProfile() async {
    final staff = await data.loadStaffProfile();
    if (staff == null) {
      await auth.signOut();
      _reset(SessionStage.notStaff);
      return;
    }
    if (!staff.mfaVerified) {
      throw StateError('The session is not MFA-verified');
    }
    profile = staff;
    enrolment = null;
    stage = SessionStage.ready;
  }

  void _reset(SessionStage to) {
    stage = to;
    profile = null;
    enrolment = null;
    _verifyFactorId = null;
    busy = false;
    notifyListeners();
  }

  Future<void> _run(
    Future<void> Function() action, {
    SessionStage? failStage,
  }) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = describeError(e);
      if (failStage != null) stage = failStage;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _signedOutSub.cancel();
    super.dispose();
  }
}

/// A short message for an error from the backend or the network.
String describeError(Object e) {
  if (e is ConsoleException) return e.message;
  if (e is StateError) return e.message;
  return 'Something went wrong. Check your connection and try again.';
}
