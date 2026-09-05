import 'package:flutter/material.dart';

/// The app's signature motif: a beacon that breathes slowly in amber when
/// idle/armed, and switches to a hard, fast crimson pulse the instant an
/// incident goes active — the same shape communicating a real state change
/// rather than decorating the screen.
class BeaconPulse extends StatefulWidget {
  final double size;
  final Color color;
  final bool urgent;
  final Widget child;

  const BeaconPulse({
    super.key,
    required this.size,
    required this.color,
    required this.child,
    this.urgent = false,
  });

  @override
  State<BeaconPulse> createState() => _BeaconPulseState();
}

class _BeaconPulseState extends State<BeaconPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.urgent ? const Duration(milliseconds: 900) : const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant BeaconPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urgent != widget.urgent) {
      _controller.duration =
          widget.urgent ? const Duration(milliseconds: 900) : const Duration(milliseconds: 3200);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _RingPainter(progress: _controller.value, color: widget.color, urgent: widget.urgent),
            child: Center(child: widget.child),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool urgent;

  _RingPainter({required this.progress, required this.color, required this.urgent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    final ringCount = urgent ? 2 : 3;

    for (var i = 0; i < ringCount; i++) {
      final t = (progress + i / ringCount) % 1.0;
      final radius = maxRadius * (0.55 + 0.45 * t);
      final opacity = (1.0 - t) * (urgent ? 0.55 : 0.35);
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = urgent ? 3.0 : 1.6;
      canvas.drawCircle(center, radius, paint);
    }

    final corePaint = Paint()..color = color.withValues(alpha: urgent ? 0.22 : 0.14);
    canvas.drawCircle(center, maxRadius * 0.5, corePaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.urgent != urgent;
}
