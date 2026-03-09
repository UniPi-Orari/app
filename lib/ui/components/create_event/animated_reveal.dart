import 'package:flutter/material.dart';

class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  final bool visible;
  final Widget child;
  final Duration duration;

  @override
  State<AnimatedReveal> createState() => AnimatedRevealState();
}

class AnimatedRevealState extends State<AnimatedReveal> with SingleTickerProviderStateMixin {
  late final AnimationController ctrl;
  late final Animation<double> height;
  late final Animation<double> opacity;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.visible ? 1.0 : 0.0,
    );
    height = CurvedAnimation(parent: ctrl, curve: Curves.easeInOut);
    opacity = CurvedAnimation(parent: ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(AnimatedReveal old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      widget.visible ? ctrl.forward() : ctrl.reverse();
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: height,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: opacity,
        child: IgnorePointer(
          ignoring: !widget.visible,
          child: widget.child,
        ),
      ),
    );
  }
}
