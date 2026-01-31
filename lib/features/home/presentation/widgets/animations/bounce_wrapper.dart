import 'package:flutter/material.dart';

class SequentialBounceWrapper extends StatefulWidget {
  final Widget child;
  final bool isLeft; // 왼쪽/오른쪽 시차 구분을 위함

  const SequentialBounceWrapper({
    super.key, 
    required this.child, 
    required this.isLeft
  });

  @override
  State<SequentialBounceWrapper> createState() => SequentialBounceWrapperState();
}

class SequentialBounceWrapperState extends State<SequentialBounceWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -15.0).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -15.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        // 원본의 시차 로직 복구
        curve: Interval(widget.isLeft ? 0.0 : 0.2, widget.isLeft ? 0.7 : 0.9, curve: Curves.linear),
      ),
    );
  }

  void play() {
    if (!_controller.isAnimating) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _bounceAnimation.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}