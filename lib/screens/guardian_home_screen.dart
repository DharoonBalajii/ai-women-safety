import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/guardian_alert.dart';
import '../models/guardian_invite.dart';
import '../models/threat_type.dart';
import '../providers/auth_provider.dart';
import '../providers/guardian_provider.dart';
import '../theme/home_theme.dart';

/// The Guardian's live dashboard: pending invitations from people who've
/// added this account to their Safety Circle, and every active SOS alert
/// from a protected user this account has an ACTIVE relationship with.
///
/// Refreshes on a short poll (see [GuardianProvider]) rather than a
/// Supabase Realtime subscription — Realtime isn't turned on for this
/// project yet. Nothing here is fabricated: an empty list reads "No active
/// alerts", never a placeholder incident.
class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  late final GuardianProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = GuardianProvider()..start();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GuardianProvider>.value(
      value: _provider,
      child: const _GuardianDashboardBody(),
    );
  }
}

class _GuardianDashboardBody extends StatelessWidget {
  const _GuardianDashboardBody();

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Sign out?', style: HomeText.title()),
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
    final guardian = context.watch<GuardianProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: HomeColors.appBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _GuardianHeader(
              phoneNumber: user?.phoneNumber,
              alertCount: guardian.alerts.length,
              onAvatarTap: () => _confirmSignOut(context),
            ),
            Expanded(
              child: RefreshIndicator(
                color: HomeColors.brandIndigo,
                onRefresh: guardian.refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (guardian.invites.isNotEmpty) ...[
                      Text('PENDING INVITATIONS', style: HomeText.eyebrow()),
                      const SizedBox(height: 10),
                      for (final invite in guardian.invites) ...[
                        _InviteCard(invite: invite),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Text('EMERGENCY ALERTS', style: HomeText.eyebrow()),
                        if (guardian.alerts.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: HomeColors.sosCrimson,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${guardian.alerts.length}',
                              style: HomeText.caption(color: Colors.white).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (guardian.loading && guardian.alerts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator(color: HomeColors.brandIndigo)),
                      )
                    else if (guardian.error != null && guardian.alerts.isEmpty)
                      _EmptyState(
                        icon: Icons.wifi_off_rounded,
                        text: guardian.error!,
                      )
                    else if (guardian.alerts.isEmpty)
                      const _EmptyState(
                        icon: Icons.verified_user_outlined,
                        text: 'No active alerts. You\'ll see a protected contact\'s SOS here '
                            'the moment they report one.',
                      )
                    else
                      for (final alert in guardian.alerts) ...[
                        _AlertCard(alert: alert),
                        const SizedBox(height: 14),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardianHeader extends StatelessWidget {
  final String? phoneNumber;
  final int alertCount;
  final VoidCallback onAvatarTap;
  const _GuardianHeader({required this.phoneNumber, required this.alertCount, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: HomeColors.appBg,
        border: Border(bottom: BorderSide(color: HomeColors.cardBorder)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/icon/app_icon.png', width: 34, height: 34, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Responder Dashboard', style: HomeText.title(color: HomeColors.brandIndigo)),
                Text(phoneNumber ?? 'Guardian', style: HomeText.caption()),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: alertCount > 0 ? HomeColors.sosCrimson.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: alertCount > 0 ? HomeColors.sosCrimson : HomeColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: alertCount > 0 ? HomeColors.sosCrimson : HomeColors.statusGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  alertCount > 0 ? '$alertCount active' : 'Live',
                  style: HomeText.caption(color: alertCount > 0 ? HomeColors.sosCrimson : HomeColors.textSecondary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onAvatarTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: HomeColors.cardBorder),
              ),
              child: const Icon(Icons.logout_rounded, color: HomeColors.textSecondary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: HomeColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Text(text, style: HomeText.body(), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final GuardianInvite invite;
  const _InviteCard({required this.invite});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.label?.isNotEmpty == true
                      ? '${invite.label} · ${invite.protectedPhoneNumber}'
                      : invite.protectedPhoneNumber,
                  style: HomeText.cardTitle(),
                ),
                const SizedBox(height: 2),
                Text('Wants to add you as a Guardian', style: HomeText.caption()),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.read<GuardianProvider>().respondToInvite(invite.relationshipId, accept: false),
            child: Text('Decline', style: HomeText.body(color: HomeColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: HomeColors.brandIndigo,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => context.read<GuardianProvider>().respondToInvite(invite.relationshipId, accept: true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final GuardianAlert alert;
  const _AlertCard({required this.alert});

  Color _statusColor() {
    switch (alert.status) {
      case AlertResponseStatus.active:
        return HomeColors.sosCrimson;
      case AlertResponseStatus.acknowledged:
        return HomeColors.caution;
      case AlertResponseStatus.responding:
        return HomeColors.brandTeal;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(alert.createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: alert.protectedPhoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _navigate() async {
    if (!alert.hasLocation) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${alert.latitude},${alert.longitude}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final guardian = context.read<GuardianProvider>();
    final statusColor = _statusColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.threatType?.label ?? 'Unclassified emergency',
                  style: HomeText.cardTitle().copyWith(fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  alert.status.label,
                  style: HomeText.caption(color: statusColor).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${alert.protectedDisplayName ?? alert.protectedPhoneNumber} · ${_timeAgo()}',
            style: HomeText.caption(),
          ),
          const SizedBox(height: 10),
          Text(
            (alert.aiSummary?.isNotEmpty ?? false) ? alert.aiSummary! : 'No AI summary reported yet.',
            style: HomeText.body(color: HomeColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.battery_std_rounded, size: 16, color: HomeColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                alert.batteryPercent != null ? '${alert.batteryPercent}% battery' : 'Battery not reported',
                style: HomeText.caption(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (alert.hasLocation)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 150,
                decoration: BoxDecoration(border: Border.all(color: HomeColors.cardBorder)),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: ll.LatLng(alert.latitude!, alert.longitude!),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.dharoonbalajii.ai_women_safety',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point: ll.LatLng(alert.latitude!, alert.longitude!),
                            width: 32,
                            height: 32,
                            child: Icon(Icons.my_location, color: statusColor, size: 26),
                          ),
                        ]),
                      ],
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${alert.latitude!.toStringAsFixed(5)}, ${alert.longitude!.toStringAsFixed(5)}',
                          style: HomeText.caption(color: HomeColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HomeColors.appBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HomeColors.cardBorder),
              ),
              child: Text('Location not yet reported', style: HomeText.caption()),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Acknowledge',
                  enabled: alert.status == AlertResponseStatus.active,
                  onTap: () => guardian.acknowledge(alert.incidentId),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Responding',
                  enabled: alert.status != AlertResponseStatus.responding,
                  onTap: () => guardian.markResponding(alert.incidentId),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Resolved',
                  filled: true,
                  color: HomeColors.statusGreen,
                  onTap: () => guardian.resolve(alert.incidentId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HomeColors.textPrimary,
                    side: const BorderSide(color: HomeColors.cardBorder),
                  ),
                  onPressed: _call,
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HomeColors.textPrimary,
                    side: const BorderSide(color: HomeColors.cardBorder),
                  ),
                  onPressed: alert.hasLocation ? _navigate : null,
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool filled;
  final Color color;
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.filled = false,
    this.color = HomeColors.brandIndigo,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 12.5)),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? color : HomeColors.textSecondary,
        side: BorderSide(color: enabled ? color : HomeColors.cardBorder),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onPressed: enabled ? onTap : null,
      child: Text(label, style: const TextStyle(fontSize: 12.5)),
    );
  }
}
