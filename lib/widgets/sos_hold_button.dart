import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/home_theme.dart';

/// The everyday-surface SOS trigger: a satin crimson panel that fills with
/// a light overlay as you hold it, matching the "personal companion" home
/// screen's calmer register — [BeaconPulse]'s ringing beacon stays reserved
/// for the actual live-emergency screen. Same deliberate-gesture safeguard
/// as the beacon: releasing early cancels harmlessly, nothing fires on tap.
class SosHoldButton extends StatefulWidget {
  final VoidCallback onArmed;
  final Duration holdDuration;

  const SosHoldButton({
    super.key,
    required this.onArmed,
    this.holdDuration = const Duration(milliseconds: 2500),
  });

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(vsync: this, duration: widget.holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          HapticFeedback.heavyImpact();
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

  void _start() {
    HapticFeedback.lightImpact();
    _holdController.forward();
  }

  void _cancel() {
    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _start(),
      onLongPressEnd: (_) => _cancel(),
      onLongPressCancel: _cancel,
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: 128,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [HomeColors.sosCrimson, HomeColors.sosCrimsonDark],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: HomeColors.sosCrimson.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Satin inner-rim sheen.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: 0.15), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                // Hold-progress fill, wiping in from the left.
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _holdController.value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
                    ),
                    Text(
                      'EMERGENCY SOS',
                      style: HomeText.title(color: Colors.white).copyWith(letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Press and hold for help',
                      style: HomeText.body(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
