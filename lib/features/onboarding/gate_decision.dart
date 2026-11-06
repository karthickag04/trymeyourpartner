import '../../shared/models/matrimonial_user.dart';
import '../../shared/models/profile_requirements.dart';
import '../../shared/state/profile_load_state.dart';

export '../../shared/models/profile_requirements.dart';
export '../../shared/state/profile_load_state.dart';

/// What the profile gate shows.
enum GateView {
  /// Sign-in or the profile is still being worked out: a spinner.
  waiting,

  /// The profile could not be loaded (e.g. no network): retry, never registration.
  loadFailed,

  /// A new member, or one missing required details: the registration form.
  register,

  /// All required details are saved: the app.
  app,
}

GateView decideGate({
  required bool authLoading,
  required bool signedIn,
  required ProfileLoadState profileState,
  required MatrimonialUser? profile,
  DateTime? now,
}) {
  if (authLoading || !signedIn) return GateView.waiting;
  switch (profileState) {
    case ProfileLoadState.notLoaded:
    case ProfileLoadState.loading:
      // A profile already in memory (e.g. during a refresh) keeps the member
      // where they are instead of flashing another screen.
      if (profile != null && hasMandatoryProfileFields(profile, now: now)) {
        return GateView.app;
      }
      return GateView.waiting;
    case ProfileLoadState.failed:
      if (profile != null && hasMandatoryProfileFields(profile, now: now)) {
        return GateView.app;
      }
      return GateView.loadFailed;
    case ProfileLoadState.loaded:
      if (profile == null) return GateView.register;
      return hasMandatoryProfileFields(profile, now: now)
          ? GateView.app
          : GateView.register;
  }
}
