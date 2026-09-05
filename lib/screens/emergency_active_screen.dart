import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../models/emergency_incident.dart';
import '../models/safe_place.dart';
import '../models/threat_level.dart';
import '../models/threat_type.dart';
import '../providers/contacts_provider.dart';
import '../providers/emergency_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/beacon_pulse.dart';
import '../widgets/incident_timeline.dart';

class EmergencyActiveScreen extends StatefulWidget {
  const EmergencyActiveScreen({super.key});

  @override
  State<EmergencyActiveScreen> createState() => _EmergencyActiveScreenState();
}

class _EmergencyActiveScreenState extends State<EmergencyActiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().load();
    });
  }

  Future<void> _confirmEnd(BuildContext context, {required bool resolved}) async {
    final emergency = context.read<EmergencyProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.inkSurfaceRaised,
        title: Text(resolved ? 'Mark as resolved?' : 'Cancel emergency?'),
        content: Text(
          resolved
              ? 'This confirms you have reached a safe place. Trusted contacts keep the final update.'
              : 'Use this only if the SOS was triggered by mistake.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Back')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(resolved ? 'Confirm safe' : 'Confirm cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (resolved) {
        await emergency.resolveIncident();
      } else {
        await emergency.cancelIncident();
      }
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyProvider>();
    final incident = emergency.activeIncident;

    if (incident == null) {
      return const Scaffold(body: Center(child: Text('No active incident.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(color: AppColors.alarmRed, shape: BoxShape.circle),
            ),
            const Text('EMERGENCY ACTIVE'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusBanner(incident: incident),
          const SizedBox(height: 16),
          _AmbientMonitorCard(emergency: emergency),
          const SizedBox(height: 16),
          _MapCard(incident: incident),
          const SizedBox(height: 16),
          _ReportInputCard(emergency: emergency),
          const SizedBox(height: 16),
          _SafeZonesCard(
            places: emergency.safePlaces,
            lookupFailed: emergency.safePlacesLookupFailed,
            onRefresh: emergency.refreshSafePlaces,
          ),
          const SizedBox(height: 16),
          _ContactsQuickActions(),
          const SizedBox(height: 16),
          Text('LIVE INCIDENT TIMELINE', style: AppText.textTheme.labelMedium),
          const SizedBox(height: 8),
          IncidentTimeline(updates: incident.updates),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmEnd(context, resolved: false),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.signalTeal),
                  onPressed: () => _confirmEnd(context, resolved: true),
                  child: const Text("I'M SAFE"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final EmergencyIncident incident;
  const _StatusBanner({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            BeaconPulse(
              size: 56,
              color: AppColors.alarmRed,
              urgent: true,
              child: Icon(incident.threatType.icon, color: AppColors.alarmRed, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(incident.threatType.label, style: AppText.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    incident.aiSummary.isNotEmpty ? incident.aiSummary : 'Awaiting voice context…',
                    style: AppText.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('[SIMULATED] ${incident.responderStage.label}', style: AppText.mono(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Runs for the life of the incident with no interaction required — the
/// point is that a phone owner who can't safely touch their screen still
/// gets covered. Shows what the AI last overheard only when there's
/// something to say; otherwise a quiet "listening" state.
class _AmbientMonitorCard extends StatelessWidget {
  final EmergencyProvider emergency;
  const _AmbientMonitorCard({required this.emergency});

  @override
  Widget build(BuildContext context) {
    final enabled = emergency.isAmbientMonitoringEnabled;
    final assessing = emergency.isAssessingAmbient;
    final assessment = emergency.latestAmbientAssessment;
    final level = assessment?.level ?? ThreatLevel.none;

    final dotColor = enabled ? level.color : AppColors.paperMuted;
    final statusLabel = !enabled
        ? 'PAUSED'
        : assessing
            ? 'LISTENING…'
            : level.label.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BeaconPulse(
                  size: 28,
                  color: dotColor,
                  urgent: enabled && level == ThreatLevel.danger,
                  child: const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AMBIENT THREAT MONITOR', style: AppText.textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(
                        statusLabel,
                        style: AppText.textTheme.titleLarge?.copyWith(color: dotColor, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: enabled ? emergency.stopAmbientMonitoring : emergency.startAmbientMonitoring,
                  child: Text(enabled ? 'PAUSE' : 'RESUME'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              assessment != null && assessment.reason.isNotEmpty
                  ? assessment.reason
                  : enabled
                      ? "Quietly listening for danger cues — no need to touch your phone."
                      : 'Not listening. Resume to let the AI watch for danger automatically.',
              style: AppText.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final EmergencyIncident incident;
  const _MapCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final location = incident.latestLocation;
    if (location == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Locating…', style: AppText.textTheme.bodyMedium),
        ),
      );
    }
    final center = ll.LatLng(location.latitude, location.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dharoonbalajii.ai_women_safety',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: center,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.my_location, color: AppColors.alarmRed, size: 30),
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
                  color: AppColors.inkBase.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                  style: AppText.mono(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two channels into the same Sarvam AI pipeline — speak or type, whichever
/// is safe to do right now. Presented as equal tabs rather than a primary
/// beacon with a text field bolted underneath, since typing is a real
/// fallback (e.g. when staying silent matters) and not a lesser option.
class _ReportInputCard extends StatefulWidget {
  final EmergencyProvider emergency;
  const _ReportInputCard({required this.emergency});

  @override
  State<_ReportInputCard> createState() => _ReportInputCardState();
}

class _ReportInputCardState extends State<_ReportInputCard> {
  bool _textMode = false;
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    widget.emergency.sendTextUpdate(text);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final emergency = widget.emergency;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('REPORT AN UPDATE', style: AppText.textTheme.labelMedium),
                const Spacer(),
                _ChannelToggle(
                  textMode: _textMode,
                  onChanged: (value) => setState(() => _textMode = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_textMode) _TextChannel(emergency: emergency, controller: _controller, onSend: _send)
            else _VoiceChannel(emergency: emergency),
          ],
        ),
      ),
    );
  }
}

class _ChannelToggle extends StatelessWidget {
  final bool textMode;
  final ValueChanged<bool> onChanged;
  const _ChannelToggle({required this.textMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.inkBase,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChannelTab(label: 'VOICE', selected: !textMode, onTap: () => onChanged(false)),
          _ChannelTab(label: 'TEXT', selected: textMode, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _ChannelTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChannelTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.beaconAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: AppText.textTheme.labelSmall?.copyWith(
            color: selected ? AppColors.inkBase : AppColors.paperMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _VoiceChannel extends StatelessWidget {
  final EmergencyProvider emergency;
  const _VoiceChannel({required this.emergency});

  @override
  Widget build(BuildContext context) {
    final label = emergency.isAnalyzingVoice
        ? 'Analyzing with Sarvam AI…'
        : emergency.isRecordingVoice
            ? 'Listening… release to send'
            : 'Hold to speak an update';

    return Row(
      children: [
        GestureDetector(
          onLongPressStart: (_) => emergency.startVoiceRecording(),
          onLongPressEnd: (_) => emergency.stopVoiceRecordingAndAnalyze(),
          child: BeaconPulse(
            size: 64,
            color: emergency.isRecordingVoice ? AppColors.alarmRed : AppColors.beaconAmber,
            urgent: emergency.isRecordingVoice,
            child: Icon(
              emergency.isAnalyzingVoice ? Icons.hourglass_top : Icons.mic,
              color: AppColors.paper,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: AppText.textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _TextChannel extends StatelessWidget {
  final EmergencyProvider emergency;
  final TextEditingController controller;
  final VoidCallback onSend;
  const _TextChannel({required this.emergency, required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final analyzing = emergency.isAnalyzingText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !analyzing,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            style: AppText.textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: "Type what's happening…",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton.filled(
            onPressed: analyzing ? null : onSend,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.beaconAmber,
              disabledBackgroundColor: AppColors.hairline,
              shape: const CircleBorder(),
            ),
            icon: analyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkBase),
                  )
                : const Icon(Icons.send_rounded, color: AppColors.inkBase),
          ),
        ),
      ],
    );
  }
}

class _SafeZonesCard extends StatelessWidget {
  final List<SafePlace> places;
  final bool lookupFailed;
  final Future<void> Function() onRefresh;

  const _SafeZonesCard({required this.places, required this.lookupFailed, required this.onRefresh});

  IconData _iconFor(SafePlaceType type) {
    switch (type) {
      case SafePlaceType.police:
        return Icons.local_police_outlined;
      case SafePlaceType.hospital:
        return Icons.local_hospital_outlined;
      case SafePlaceType.publicPlace:
        return Icons.storefront_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('NEAREST SAFE PLACES', style: AppText.textTheme.labelMedium)),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: onRefresh,
                ),
              ],
            ),
            if (places.isEmpty && lookupFailed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Couldn't get a location fix — enable location access and tap refresh.",
                  style: AppText.textTheme.bodyMedium,
                ),
              )
            else if (places.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Finding nearby safe zones…', style: AppText.textTheme.bodyMedium),
              )
            else
              ...places.take(4).map(
                    (place) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(_iconFor(place.type), size: 18, color: AppColors.paperMuted),
                          const SizedBox(width: 10),
                          Expanded(child: Text(place.name, style: AppText.textTheme.bodyMedium)),
                          Text(place.distanceLabel, style: AppText.mono(fontSize: 12)),
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

class _ContactsQuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsProvider>().contacts;
    final emergency = context.read<EmergencyProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TRUSTED CONTACTS', style: AppText.textTheme.labelMedium),
            const SizedBox(height: 8),
            if (contacts.isEmpty)
              Text('No contacts added yet.', style: AppText.textTheme.bodyMedium)
            else ...[
              for (final contact in contacts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${contact.name} · ${contact.relationship}',
                            style: AppText.textTheme.bodyMedium),
                      ),
                      TextButton(
                        onPressed: () => emergency.alertService.notifyContact(
                          contact,
                          emergency.activeIncident!,
                        ),
                        child: const Text('NOTIFY'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => emergency.notifyAllContacts(contacts),
                icon: const Icon(Icons.campaign_outlined, size: 18),
                label: const Text('NOTIFY ALL CONTACTS'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
