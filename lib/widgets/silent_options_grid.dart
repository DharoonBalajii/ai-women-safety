import 'package:flutter/material.dart';

import '../models/threat_type.dart';
import '../theme/app_theme.dart';

/// Explicit, deliberate quick-report options. Unlike the primary beacon
/// these are single-tap: the deliberateness of picking a specific option
/// (vs. reflexively hitting one big button) is itself the safeguard.
class SilentOptionsGrid extends StatelessWidget {
  final void Function(ThreatType type) onSelect;

  const SilentOptionsGrid({super.key, required this.onSelect});

  static const _options = [
    ThreatType.following,
    ThreatType.threatened,
    ThreatType.medical,
    ThreatType.accident,
  ];

  Widget _tile(ThreatType type) {
    return Expanded(
      child: Material(
        color: AppColors.inkSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelect(type),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                Icon(type.icon, color: AppColors.paperMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type.label,
                    style: AppText.textTheme.bodyMedium?.copyWith(color: AppColors.paper),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
}
