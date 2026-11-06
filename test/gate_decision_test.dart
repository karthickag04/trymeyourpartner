import 'package:flutter_test/flutter_test.dart';
import 'package:trymeyourpartner/features/onboarding/gate_decision.dart';
import 'package:trymeyourpartner/shared/models/matrimonial_user.dart';

import 'helpers/profiles.dart';

void main() {
  final now = DateTime(2026, 11, 5);
  final complete = sampleProfile();
  final noCaste = sampleProfile({'caste': null, 'caste_id': null});

  GateView decide(
    ProfileLoadState state,
    MatrimonialUser? profile, {
    bool authLoading = false,
    bool signedIn = true,
  }) => decideGate(
    authLoading: authLoading,
    signedIn: signedIn,
    profileState: state,
    profile: profile,
    now: now,
  );

  group('never shows registration before the profile is known', () {
    test('sign-in still being checked, or signed out', () {
      expect(
        decide(ProfileLoadState.loaded, null, authLoading: true),
        GateView.waiting,
      );
      expect(
        decide(ProfileLoadState.loaded, null, signedIn: false),
        GateView.waiting,
      );
    });

    test('first frame after launch: not loaded yet', () {
      expect(decide(ProfileLoadState.notLoaded, null), GateView.waiting);
    });

    test('loading', () {
      expect(decide(ProfileLoadState.loading, null), GateView.waiting);
      expect(decide(ProfileLoadState.loading, noCaste), GateView.waiting);
    });

    test('load failed (e.g. no network): retry, not registration', () {
      expect(decide(ProfileLoadState.failed, null), GateView.loadFailed);
      expect(decide(ProfileLoadState.failed, noCaste), GateView.loadFailed);
    });

    test(
      'a complete profile already shown stays during a refresh or failure',
      () {
        expect(decide(ProfileLoadState.loading, complete), GateView.app);
        expect(decide(ProfileLoadState.failed, complete), GateView.app);
      },
    );
  });

  group('registration only for new members or missing required details', () {
    test('new member: the load succeeded and found no profile', () {
      expect(decide(ProfileLoadState.loaded, null), GateView.register);
    });

    final missing = <String, Map<String, dynamic>>{
      'caste': {'caste': null, 'caste_id': null},
      'religion': {'religion': ''},
      'state': {'state': null, 'state_id': null},
      'district': {'district': null, 'district_id': null},
      'education': {'education': ' '},
      'a date of birth 18+ years ago': {'date_of_birth': '2010-01-01'},
    };
    for (final e in missing.entries) {
      test('missing ${e.key} -> registration', () {
        final p = sampleProfile(e.value);
        expect(hasMandatoryProfileFields(p, now: now), isFalse);
        expect(decide(ProfileLoadState.loaded, p), GateView.register);
      });
    }

    test('all required details saved -> the app, on every launch', () {
      expect(hasMandatoryProfileFields(complete, now: now), isTrue);
      expect(decide(ProfileLoadState.loaded, complete), GateView.app);
    });
  });
}
