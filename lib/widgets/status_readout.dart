import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// A small cockpit-style status row: live clock + Sarvam AI link state.
/// Encodes real system state rather than decorating the header.
class StatusReadout extends StatefulWidget {
  final bool sarvamConfigured;

  const StatusReadout({super.key, required this.sarvamConfigured});

  @override
  State<StatusReadout> createState() => _StatusReadoutState();
}

class _StatusReadoutState extends State<StatusReadout> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.sarvamConfigured ? AppColors.signalTeal : AppColors.beaconAmber;
    final statusLabel = widget.sarvamConfigured ? 'SARVAM AI · LIVE' : 'SARVAM AI · DEMO MODE';
    return Row(
      children: [
        Text(DateFormat('HH:mm:ss').format(_now), style: AppText.mono(fontSize: 12)),
        const SizedBox(width: 12),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(statusLabel, style: AppText.mono(fontSize: 11, color: statusColor)),
      ],
    );
  }
}
