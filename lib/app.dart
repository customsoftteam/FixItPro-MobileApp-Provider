import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell/provider_shell.dart';
import 'theme/app_theme.dart';

class FixItProApp extends StatelessWidget {
  const FixItProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixItPro Provider',
      theme: AppTheme.lightTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: true),
      home: const _AuthBootstrapScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/shell': (_) => const ProviderShell(),
      },
    );
  }
}

class _AuthBootstrapScreen extends StatefulWidget {
  const _AuthBootstrapScreen();

  @override
  State<_AuthBootstrapScreen> createState() => _AuthBootstrapScreenState();
}

class _AuthBootstrapScreenState extends State<_AuthBootstrapScreen> {
  final AuthService _authService = AuthService.instance;
  late Future<_LaunchTarget> _launchTargetFuture;

  @override
  void initState() {
    super.initState();
    _launchTargetFuture = _resolveLaunchTarget();
  }

  Future<_LaunchTarget> _resolveLaunchTarget() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      return _LaunchTarget.login;
    }

    final provider = await _authService.getStoredProvider();
    if (provider == null) {
      return _LaunchTarget.shell;
    }

    final onboardingCompleted = provider['onboardingCompleted'] == true;
    return onboardingCompleted ? _LaunchTarget.shell : _LaunchTarget.onboarding;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LaunchTarget>(
      future: _launchTargetFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final target = snapshot.data ?? _LaunchTarget.login;
        return switch (target) {
          _LaunchTarget.login => const LoginScreen(),
          _LaunchTarget.onboarding => const OnboardingScreen(),
          _LaunchTarget.shell => const ProviderShell(),
        };
      },
    );
  }
}

enum _LaunchTarget {
  login,
  onboarding,
  shell,
}
