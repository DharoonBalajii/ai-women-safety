import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'beacon_pulse.dart';

/// The primary trigger. Holding it down for [holdDuration] arms the SOS —
/// releasing early cancels harmlessly. This *is* the app's accidental-
/// trigger safeguard: a deliberate, unmistakable gesture rather than a
/// confirmation dialog that could be tapped through on reflex.
class SosButton extends StatefulWidget {
  final VoidCallback onArmed;
  final Duration holdDuration;

  const SosButton({
    super.key,
    required this.onArmed,
    this.holdDuration = const Duration(milliseconds: 1400),
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(vsync: this, duration: widget.holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onArmed();
          _holdController.reset();
        }
      });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 220.0;
    return GestureDetector(
      onLongPressStart: (_) => _holdController.forward(),
      onLongPressEnd: (_) => _holdController.reverse(),
      onLongPressCancel: () => _holdController.reverse(),
      child: BeaconPulse(
        size: size,
        color: AppColors.beaconAmber,
        child: AnimatedBuilder(
          animation: _holdController,
          builder: (context, _) {
            return Container(
              width: size * 0.62,
              height: size * 0.62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(AppColors.inkSurfaceRaised, AppColors.beaconAmber, _holdController.value),
                border: Border.all(color: AppColors.beaconAmber, width: 2.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_holdController.value > 0)
                    SizedBox(
                      width: size * 0.62,
                      height: size * 0.62,
                      child: CircularProgressIndicator(
                        value: _holdController.value,
                        strokeWidth: 3,
                        color: AppColors.inkBase,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sos_rounded,
                        size: 40,
                        color: Color.lerp(AppColors.beaconAmber, AppColors.inkBase, _holdController.value),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'HOLD TO ALERT',
                        style: AppText.textTheme.labelSmall?.copyWith(
                          color: Color.lerp(
                              AppColors.paperMuted, AppColors.inkBase, _holdController.value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
