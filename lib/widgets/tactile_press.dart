import 'package:calsnap/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Responds immediately on pointer-down with subtle compression and optional haptics.
class TactilePress extends StatefulWidget {
  const TactilePress({
    super.key,
    required this.child,
    this.disabled = false,
    this.enableHaptic = false,
  });

  final Widget child;
  final bool disabled;
  final bool enableHaptic;

  @override
  State<TactilePress> createState() => _TactilePressState();
}

class _TactilePressState extends State<TactilePress> {
  bool _pressed = false;

  void _handlePointerDown(PointerDownEvent _) {
    if (widget.disabled) {
      return;
    }
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    if (!_pressed) {
      setState(() => _pressed = true);
    }
  }

  void _release() {
    if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final scale = (!widget.disabled && !reduceMotion && _pressed) ? 0.97 : 1.0;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedScale(
        scale: scale,
        duration: reduceMotion ? Duration.zero : CalSnapMotion.pressDuration,
        curve: CalSnapMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
