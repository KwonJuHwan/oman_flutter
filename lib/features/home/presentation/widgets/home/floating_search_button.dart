import 'package:flutter/material.dart';

class FloatingSearchButton extends StatelessWidget {
  final bool isVisible;
  final bool isSlidingDown;
  final bool isPressed;
  final VoidCallback onTap;

  const FloatingSearchButton({
    super.key,
    required this.isVisible,
    required this.isSlidingDown,
    required this.isPressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool showPosition = isVisible && !isSlidingDown;
    const Color youtubeRed = Color(0xFFFF0000);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: showPosition ? Curves.easeOutBack : Curves.easeInOut,
      bottom: showPosition ? 30 : -100, 
      left: 0, right: 0,
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 100),
          scale: isPressed ? 0.9 : 1.0,
          curve: Curves.easeInOut,
          child: GestureDetector(
            onTap: isVisible ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: youtubeRed,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  if (isVisible)
                    BoxShadow(
                      color: youtubeRed.withValues(alpha: 0.4), 
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text("요리와 재료로 영상 찾기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pretendard')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}