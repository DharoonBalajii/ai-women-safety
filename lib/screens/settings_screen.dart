import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../services/app_settings_service.dart';
import '../theme/home_theme.dart';

/// Personal Details: the signed-in person's own account info and sign-out
/// — nothing about AI configuration here anymore. The Sarvam key is an
/// admin-provisioned backend secret now; the app never holds or shows one.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoTriggerOnLaunch = false;
  bool _loadedAutoTrigger = false;

  @override
  void initState() {
    super.initState();
    appSettingsService.getAutoTriggerOnLaunch().then((value) {
      if (!mounted) return;
      setState(() {
        _autoTriggerOnLaunch = value;
        _loadedAutoTrigger = true;
      });
    });
  }

  Future<void> _setAutoTrigger(bool value) async {
    setState(() => _autoTriggerOnLaunch = value);
    await appSettingsService.setAutoTriggerOnLaunch(value);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Sign out?', style: HomeText.title()),
        content: Text("You'll need to verify your phone number again to sign back in.", style: HomeText.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: HomeText.body(color: HomeColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HomeColors.sosCrimson),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: HomeColors.appBg,
      appBar: AppBar(
        backgroundColor: HomeColors.appBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: HomeColors.textPrimary),
        title: Text('Personal Details', style: HomeText.title()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('ACCOUNT', style: HomeText.eyebrow()),
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: HomeColors.brandIndigo.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_outline_rounded, color: HomeColors.brandIndigo),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.phoneNumber ?? 'Unknown', style: HomeText.cardTitle()),
                      const SizedBox(height: 2),
                      Text(user?.role.label ?? '', style: HomeText.caption()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: HomeColors.sosCrimson,
                side: const BorderSide(color: HomeColors.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _confirmSignOut(context),
              child: const Text('Sign out'),
            ),
          ),
          if (user?.role == UserRole.protected) ...[
            const SizedBox(height: 24),
            Text('SAFETY', style: HomeText.eyebrow()),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auto-trigger SOS on launch', style: HomeText.cardTitle()),
                        const SizedBox(height: 4),
                        Text(
                          _autoTriggerOnLaunch
                              ? 'Opening the app immediately starts an emergency — no button press needed.'
                              : 'Off: opening the app goes to your normal Home screen. Use the SOS button to '
                                  'start an emergency manually.',
                          style: HomeText.caption(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _autoTriggerOnLaunch,
                    activeThumbColor: HomeColors.sosCrimson,
                    onChanged: _loadedAutoTrigger ? _setAutoTrigger : null,
                  ),
                ],
              ),
            ),
          ],
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
              'AI analysis (voice, text, and ambient monitoring) runs through this app\'s own backend, '
              "which holds the Sarvam AI key — it's never stored on this device. Trusted-contact alerts open "
              "your phone's own SMS composer prefilled with your live location and the AI's assessment — you "
              "still send it yourself. This app does not contact police or emergency services directly; in a "
              "real emergency, also call your local emergency number.",
              style: HomeText.body(color: HomeColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
