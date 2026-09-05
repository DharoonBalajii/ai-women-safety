import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/emergency_incident.dart';
import '../models/threat_type.dart';
import '../models/trusted_contact.dart';
import '../providers/contacts_provider.dart';
import '../providers/emergency_provider.dart';
import '../services/location_service.dart';
import '../theme/home_theme.dart';
import '../widgets/sos_hold_button.dart';
import 'contacts_screen.dart';
import 'emergency_active_screen.dart';
import 'history_screen.dart';
import 'nearby_help_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openEmergency(BuildContext context) async {
    final emergency = context.read<EmergencyProvider>();
    if (!emergency.hasActiveIncident) {
      await emergency.triggerVoiceSOS();
    }
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyActiveScreen()));
    }
  }

  Future<void> _reportSilently(BuildContext context, ThreatType type) async {
    final emergency = context.read<EmergencyProvider>();
    if (!emergency.hasActiveIncident) {
      await emergency.triggerSilentSOS(type);
    }
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencyActiveScreen()));
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyProvider>();
    final contacts = context.watch<ContactsProvider>().contacts;

    return Scaffold(
      backgroundColor: HomeColors.appBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(onAvatarTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                )),
            Expanded(
              child: RefreshIndicator(
                color: HomeColors.brandIndigo,
                onRefresh: () => context.read<EmergencyProvider>().loadHistory(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text('${_greeting()} 👋', style: HomeText.greeting()),
                    const SizedBox(height: 4),
                    Text('Your safety network is ready.', style: HomeText.body()),
                    const SizedBox(height: 16),
                    _SafetyStatusCard(
                      hasActiveIncident: emergency.hasActiveIncident,
                      contactsConnected: contacts.isNotEmpty,
                      onTapActive: () => _openEmergency(context),
                    ),
                    const SizedBox(height: 20),
                    SosHoldButton(onArmed: () => _openEmergency(context)),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Directly alerts emergency responders & your trusted contacts',
                        textAlign: TextAlign.center,
                        style: HomeText.caption(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('SILENT REPORT', style: HomeText.eyebrow()),
                    const SizedBox(height: 10),
                    _SilentReportGrid(onSelect: (type) => _reportSilently(context, type)),
                    const SizedBox(height: 26),
                    Text('QUICK ACCESS', style: HomeText.eyebrow()),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAccessCard(
                            icon: Icons.mic_none_rounded,
                            iconColor: HomeColors.brandTeal,
                            title: 'Talk to Safety AI',
                            subtitle: "Tell us what's happening",
                            onTap: () => _openEmergency(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAccessCard(
                            icon: Icons.near_me_rounded,
                            iconColor: HomeColors.brandIndigo,
                            title: 'Nearby Help',
                            subtitle: 'Find help around you',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NearbyHelpScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SafetyCircleCard(
                      contacts: contacts,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ContactsScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RecentActivityCard(
                      history: emergency.history,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                    ),
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

class _HomeHeader extends StatelessWidget {
  final VoidCallback onAvatarTap;
  const _HomeHeader({required this.onAvatarTap});

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
                Text('Raksha Thunai', style: HomeText.title(color: HomeColors.brandIndigo)),
                Text('Personal Companion', style: HomeText.caption()),
              ],
            ),
          ),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications')),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: HomeColors.cardBorder),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.notifications_outlined, color: HomeColors.brandIndigo, size: 21),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: HomeColors.statusGreen, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onAvatarTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HomeColors.brandIndigo.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.person_outline_rounded, color: HomeColors.brandIndigo, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyStatusCard extends StatefulWidget {
  final bool hasActiveIncident;
  final bool contactsConnected;
  final VoidCallback onTapActive;

  const _SafetyStatusCard({
    required this.hasActiveIncident,
    required this.contactsConnected,
    required this.onTapActive,
  });

  @override
  State<_SafetyStatusCard> createState() => _SafetyStatusCardState();
}

class _SafetyStatusCardState extends State<_SafetyStatusCard> {
  final _locationService = LocationService();
  bool? _locationActive;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    final active = await _locationService.isActive();
    if (mounted) setState(() => _locationActive = active);
  }

  @override
  Widget build(BuildContext context) {
    final emergency = widget.hasActiveIncident;
    final locationKnown = _locationActive != null;
    final locationOn = _locationActive ?? false;

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (emergency ? HomeColors.sosCrimson : HomeColors.statusGreen).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  emergency ? Icons.warning_rounded : Icons.verified_user_rounded,
                  color: emergency ? HomeColors.sosCrimson : HomeColors.statusGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  emergency ? 'Emergency in progress' : "You're safe",
                  style: HomeText.cardTitle().copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (emergency ? HomeColors.sosCrimson : HomeColors.statusGreen).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: (emergency ? HomeColors.sosCrimson : HomeColors.statusGreen).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: emergency ? HomeColors.sosCrimson : HomeColors.statusGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      emergency ? 'TAP TO VIEW' : 'Active & Protected',
                      style: HomeText.caption(color: emergency ? HomeColors.sosCrimson : HomeColors.statusGreen)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: HomeColors.appBg, height: 1, thickness: 8),
          const SizedBox(height: 4),
          _StatusLine(
            icon: Icons.location_on_outlined,
            iconColor: HomeColors.brandTeal,
            label: locationKnown
                ? (locationOn ? 'Location services are active' : 'Location services are off')
                : 'Checking location services…',
          ),
          const SizedBox(height: 8),
          _StatusLine(
            icon: Icons.group_outlined,
            iconColor: HomeColors.brandIndigo,
            label: widget.contactsConnected
                ? 'Your safety circle is connected'
                : 'Add a trusted contact to connect your circle',
          ),
        ],
      ),
    );

    if (!emergency) return card;
    return InkWell(borderRadius: BorderRadius.circular(20), onTap: widget.onTapActive, child: card);
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _StatusLine({required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: HomeText.body(color: HomeColors.textPrimary).copyWith(fontSize: 13))),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HomeColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: HomeText.cardTitle()),
            const SizedBox(height: 3),
            Text(subtitle, style: HomeText.caption()),
          ],
        ),
      ),
    );
  }
}

class _SafetyCircleCard extends StatelessWidget {
  final List<TrustedContact> contacts;
  final VoidCallback onTap;
  const _SafetyCircleCard({required this.contacts, required this.onTap});

  static const _avatarColors = [Color(0xFFECE8E1), Color(0xFFE2EBE8), Color(0xFFE9EDF5)];
  static const _avatarTextColors = [HomeColors.brandIndigo, HomeColors.brandTeal, HomeColors.brandIndigo];

  @override
  Widget build(BuildContext context) {
    final preview = contacts.take(3).toList();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HomeColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            if (preview.isNotEmpty)
              SizedBox(
                width: 26.0 + preview.length * 20.0,
                height: 36,
                child: Stack(
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      Positioned(
                        left: i * 20.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _avatarColors[i % _avatarColors.length],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            preview[i].name.isNotEmpty ? preview[i].name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: _avatarTextColors[i % _avatarTextColors.length],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: HomeColors.appBg, shape: BoxShape.circle, border: Border.all(color: HomeColors.cardBorder)),
                child: const Icon(Icons.group_outlined, size: 18, color: HomeColors.textSecondary),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Safety Circle', style: HomeText.cardTitle()),
                  const SizedBox(height: 2),
                  Text(
                    contacts.isEmpty
                        ? 'No trusted contacts yet — tap to add one'
                        : '${contacts.length} ${contacts.length == 1 ? 'person' : 'people'} ready to support you',
                    style: HomeText.caption(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: HomeColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<EmergencyIncident> history;
  final VoidCallback onTap;
  const _RecentActivityCard({required this.history, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final latest = history.isNotEmpty ? history.first : null;
    final resolved = latest?.status == IncidentStatus.resolved;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HomeColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: (resolved ? HomeColors.statusGreen : HomeColors.textSecondary).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                latest == null
                    ? Icons.history_rounded
                    : resolved
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                size: 17,
                color: resolved ? HomeColors.statusGreen : HomeColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latest == null
                        ? 'No recent activity'
                        : resolved
                            ? 'Safety check completed'
                            : '${latest.threatType.label} — cancelled',
                    style: HomeText.cardTitle().copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    latest?.endTime != null
                        ? DateFormat("MMM d 'at' h:mm a").format(latest!.endTime!.toLocal())
                        : 'Your incident history will appear here',
                    style: HomeText.caption(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-tap, no-hold reports for when even 2.5s on the SOS button is too
/// slow or too visible — a deliberate, separate gesture from the main
/// beacon, not a smaller version of it.
class _SilentReportGrid extends StatelessWidget {
  final void Function(ThreatType type) onSelect;
  const _SilentReportGrid({required this.onSelect});

  static const _options = [
    ThreatType.following,
    ThreatType.threatened,
    ThreatType.medical,
    ThreatType.accident,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [_tile(_options[0]), const SizedBox(width: 12), _tile(_options[1])]),
        const SizedBox(height: 12),
        Row(children: [_tile(_options[2]), const SizedBox(width: 12), _tile(_options[3])]),
      ],
    );
  }

  Widget _tile(ThreatType type) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onSelect(type),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomeColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(type.icon, color: HomeColors.textSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(type.label, style: HomeText.cardTitle().copyWith(fontSize: 13), maxLines: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
