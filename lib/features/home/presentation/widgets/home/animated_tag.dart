import 'package:flutter/material.dart';

class AnimatedTag extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;

  const AnimatedTag({
    super.key,
    required this.label,
    required this.color,
    required this.onRemove,
  });

  @override
  State<AnimatedTag> createState() => _AnimatedTagState();
}

class _AnimatedTagState extends State<AnimatedTag> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, 
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRemove() {
    _controller.reverse().then((_) {
      widget.onRemove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _handleRemove,
              child: Icon(
                Icons.close,
                size: 14,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}