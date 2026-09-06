import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/home_theme.dart';

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
      backgroundColor: HomeColors.appBg,
      appBar: AppBar(
        backgroundColor: HomeColors.appBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: HomeColors.textPrimary),
        title: Text('Profile', style: HomeText.title()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('SARVAM AI', style: HomeText.eyebrow()),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: HomeColors.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.isSarvamConfigured
                      ? 'A key is configured. Voice SOS and ambient monitoring use live speech-to-text and AI analysis.'
                      : "No key yet — voice reports and ambient monitoring can't be analyzed without one. Your exact location is still shared either way.",
                  style: HomeText.body(color: HomeColors.textPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _keyController,
                  obscureText: true,
                  style: HomeText.body(color: HomeColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Sarvam API subscription key',
                    labelStyle: HomeText.body(),
                    filled: true,
                    fillColor: HomeColors.appBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: HomeColors.brandIndigo, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: HomeColors.brandIndigo,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => settings.setSarvamApiKey(_keyController.text),
                        child: const Text('Save key'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HomeColors.textPrimary,
                        side: const BorderSide(color: HomeColors.cardBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
          const SizedBox(height: 24),
          Text('ABOUT', style: HomeText.eyebrow()),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: HomeColors.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              'Your Sarvam AI key is stored only on this device. Trusted-contact alerts open your '
              "phone's own SMS composer prefilled with your live location and the AI's assessment — "
              "you still send it yourself. This app does not contact police or emergency services "
              "directly; in a real emergency, also call your local emergency number.",
              style: HomeText.body(color: HomeColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
