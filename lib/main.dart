import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/user_role.dart';
import 'providers/auth_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/emergency_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/guardian_home_screen.dart';
import 'screens/main_shell_screen.dart';
import 'services/quick_action_service.dart';
import 'theme/app_theme.dart';
import 'theme/home_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const AiWomenSafetyApp());
}

class AiWomenSafetyApp extends StatefulWidget {
  const AiWomenSafetyApp({super.key});

  @override
  State<AiWomenSafetyApp> createState() => _AiWomenSafetyAppState();
}

class _AiWomenSafetyAppState extends State<AiWomenSafetyApp> {
  final _quickActionService = QuickActionService();
  late final EmergencyProvider _emergencyProvider;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _emergencyProvider = EmergencyProvider()..loadHistory();
    _authProvider = AuthProvider()..restoreSession();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initQuickActions());
  }

  Future<void> _initQuickActions() async {
    await _quickActionService.initialize(onSosShortcut: () async {
      if (!_authProvider.isSignedIn) return;
      if (!_emergencyProvider.hasActiveIncident) {
        await _emergencyProvider.triggerVoiceSOS();
      }
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const EmergencyActiveScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => ContactsProvider()..load()),
        ChangeNotifierProvider.value(value: _emergencyProvider),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Raksha Thunai',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Shows the sign-in flow to a signed-out or not-yet-checked person, and
/// the right home surface once a session is confirmed — returning users
/// with a valid stored session skip the auth screen entirely.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.checking:
        return const Scaffold(
          backgroundColor: HomeColors.appBg,
          body: Center(child: CircularProgressIndicator(color: HomeColors.brandIndigo)),
        );
      case AuthStatus.signedOut:
        return const AuthScreen();
      case AuthStatus.signedIn:
        return auth.user?.role == UserRole.guardian ? const GuardianHomeScreen() : const MainShellScreen();
    }
  }
}
