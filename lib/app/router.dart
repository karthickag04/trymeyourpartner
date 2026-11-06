import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/discovery/matches_screen.dart';
import '../features/discovery/search_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/matrimonial_main_screen.dart';
import '../features/interests/interests_screen.dart';
import '../features/onboarding/profile_completion_gate.dart';
import '../features/profile/profile_link_screen.dart';
import '../features/profile/profile_screen.dart';
import '../shared/models/matrimonial_user.dart';

/// URL paths. Each main tab has its own address, and every profile can be
/// opened (and shared) at `/p/<profile code>`.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const matches = '/matches';
  static const search = '/search';
  static const interests = '/interests';
  static const profile = '/profile';
  static String profileLink(String code) => '/p/$code';
}

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.matchedLocation;
      if (path == AppRoutes.splash) return null;
      if (auth.isLoading) return null; // wait until the session is known
      final loggingIn = path == AppRoutes.login;
      if (!auth.isAuthenticated) {
        if (loggingIn) return null;
        // Remember where the visitor was going (e.g. a shared profile link).
        return Uri(
          path: AppRoutes.login,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      if (loggingIn) {
        final from = state.uri.queryParameters['from'];
        return (from != null && from.startsWith('/') && from != AppRoutes.login)
            ? from
            : AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => AppRoutes.home),
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const AuthScreen()),
      GoRoute(
        path: '/p/:code',
        builder: (_, state) => ProfileCompletionGate(
          child: ProfileLinkScreen(
            code: state.pathParameters['code']!,
            preloaded: state.extra is MatrimonialUser
                ? state.extra as MatrimonialUser
                : null,
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) =>
            ProfileCompletionGate(child: MatrimonialMainScreen(shell: shell)),
        branches: [
          _tab(AppRoutes.home, const NewMatrimonialHomeScreen()),
          _tab(AppRoutes.matches, const MatchesScreen()),
          _tab(AppRoutes.search, const SearchScreen()),
          _tab(AppRoutes.interests, const InterestsScreen()),
          _tab(AppRoutes.profile, const ProfileScreen()),
        ],
      ),
    ],
  );
}

StatefulShellBranch _tab(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, __) => screen)],
);

/// Opens a profile at its shareable URL. Passing the already-loaded profile
/// avoids a second fetch; a link opened directly loads it by code.
void openProfile(BuildContext context, MatrimonialUser profile) {
  final code = profile.profileId.isNotEmpty ? profile.profileId : profile.id;
  context.push(AppRoutes.profileLink(code), extra: profile);
}
