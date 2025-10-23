import 'package:flutter/material.dart';

enum AnimationType { opacity, translateY }

class FadeAnimation extends StatefulWidget {
  final double delay;
  final Widget child;

  const FadeAnimation(this.delay, this.child);

  @override
  _FadeAnimationState createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _translateYAnimation;

  @override
  void initState() {
    super.initState();

    // AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    // Tween'leri başlat
    _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(widget.delay, 1.0, curve: Curves.easeInOut),
    ));

    _translateYAnimation = Tween(begin: -30.0, end: 0.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(widget.delay, 1.0, curve: Curves.easeInOut),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Transform.translate(
        offset: Offset(0, _translateYAnimation.value),
        child: widget.child,
      ),
    );
  }
}
