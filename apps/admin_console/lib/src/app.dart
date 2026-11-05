import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'navigation.dart';
import 'screens/console_shell.dart';
import 'screens/dashboard_screen.dart';
import 'screens/mfa_screen.dart';
import 'screens/refused_screen.dart';
import 'screens/roles_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/staff_screen.dart';
import 'session/session_controller.dart';
import 'theme.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key, required this.controller});

  final SessionController controller;

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final GoRouter _router = buildRouter(widget.controller);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionController>.value(
      value: widget.controller,
      child: MaterialApp.router(
        title: 'TryMeYourPartner Admin',
        debugShowCheckedModeBanner: false,
        theme: consoleTheme(Brightness.light),
        darkTheme: consoleTheme(Brightness.dark),
        routerConfig: _router,
      ),
    );
  }
}

GoRouter buildRouter(SessionController session) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: session,
    redirect: (context, state) => _redirect(session, state.matchedLocation),
    routes: [
      GoRoute(path: '/starting', builder: (_, _) => const _StartingScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/refused', builder: (_, _) => const RefusedScreen()),
      GoRoute(path: '/mfa', builder: (_, _) => const MfaScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            ConsoleShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(path: '/staff', builder: (_, _) => const StaffScreen()),
          GoRoute(path: '/roles', builder: (_, _) => const RolesScreen()),
        ],
      ),
    ],
  );
}

String? _redirect(SessionController session, String location) {
  String? only(String path) => location == path ? null : path;
  switch (session.stage) {
    case SessionStage.starting:
      return only('/starting');
    case SessionStage.signedOut:
      return only('/sign-in');
    case SessionStage.notStaff:
      return only('/refused');
    case SessionStage.mfaEnrol:
    case SessionStage.mfaVerify:
      return only('/mfa');
    case SessionStage.ready:
      final allowed = sectionsFor(session.profile!).map((s) => s.path);
      return allowed.contains(location) ? null : '/dashboard';
  }
}

class _StartingScreen extends StatelessWidget {
  const _StartingScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
