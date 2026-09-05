import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: context.read<SettingsProvider>().sarvamApiKey ?? '');
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('SARVAM AI', style: AppText.textTheme.labelMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.isSarvamConfigured
                        ? 'A key is configured. Voice SOS and ambient monitoring use live speech-to-text and AI analysis.'
                        : "No key yet — voice reports and ambient monitoring can't be analyzed without one. Your exact location is still shared either way.",
                    style: AppText.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Sarvam API subscription key'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => settings.setSarvamApiKey(_keyController.text),
                          child: const Text('Save key'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          _keyController.clear();
                          settings.setSarvamApiKey(null);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('ABOUT', style: AppText.textTheme.labelMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'This is a hackathon prototype. The key is stored only on this device — there is no backend yet, '
                'so trusted-contact alerts open your phone\'s own SMS composer prefilled with the emergency details, '
                'and the responder-dispatch timeline is simulated to demonstrate the intended flow.',
                style: AppText.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
