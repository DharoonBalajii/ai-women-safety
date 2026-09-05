import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/threat_type.dart';
import '../providers/emergency_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/silent_options_grid.dart';
import '../widgets/sos_button.dart';
import '../widgets/status_readout.dart';
import 'contacts_screen.dart';
import 'emergency_active_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _arm(BuildContext context) async {
    final emergency = context.read<EmergencyProvider>();
    await emergency.triggerVoiceSOS();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EmergencyActiveScreen()),
      );
    }
  }

  Future<void> _armSilent(BuildContext context, ThreatType type) async {
    final emergency = context.read<EmergencyProvider>();
    await emergency.triggerSilentSOS(type);
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EmergencyActiveScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sarvamConfigured = context.watch<SettingsProvider>().isSarvamConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI WOMEN SAFETY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Incident history',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.contacts_rounded),
            tooltip: 'Trusted contacts',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ContactsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      StatusReadout(sarvamConfigured: sarvamConfigured),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SosButton(onArmed: () => _arm(context)),
                              const SizedBox(height: 20),
                              Text(
                                'Hold the beacon for 1.5s to start\na voice-guided emergency session.',
                                textAlign: TextAlign.center,
                                style: AppText.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SILENT REPORT', style: AppText.textTheme.labelMedium),
                          const SizedBox(height: 12),
                          SilentOptionsGrid(onSelect: (type) => _armSilent(context, type)),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
