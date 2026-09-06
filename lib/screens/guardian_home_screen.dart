import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/home_theme.dart';

/// Placeholder landing spot for a signed-in Guardian. The real dashboard —
/// live SOS alerts from linked Protected users via Supabase Realtime,
/// acknowledge/responding/resolved, map preview, call/navigate — needs the
/// guardian-linking flow and Realtime wiring built first; showing fake
/// alerts here to look finished would violate the same "no fabricated
/// data" rule the rest of this app follows. This screen is honest about
/// that instead.
class GuardianHomeScreen extends StatelessWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: HomeColors.appBg,
      appBar: AppBar(
        backgroundColor: HomeColors.appBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Guardian', style: HomeText.title()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: HomeColors.textSecondary),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_moon_outlined, size: 48, color: HomeColors.brandIndigo.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('Guardian dashboard is coming soon', style: HomeText.title(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                "You're signed in as ${user?.phoneNumber ?? 'a Guardian'}. Live SOS alerts from people who "
                "add you to their Safety Circle will appear here once that connection is built — this screen "
                "won't show placeholder alerts in the meantime.",
                style: HomeText.body(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
