import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/contacts_provider.dart';
import 'providers/emergency_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/emergency_active_screen.dart';
import 'screens/home_screen.dart';
import 'services/quick_action_service.dart';
import 'theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _emergencyProvider = EmergencyProvider()..loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initQuickActions());
  }

  Future<void> _initQuickActions() async {
    await _quickActionService.initialize(onSosShortcut: () async {
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
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()..load()),
        ChangeNotifierProvider.value(value: _emergencyProvider),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Raksha Thunai',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
