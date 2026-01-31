import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/search_type.dart';
import 'package:oman_fe/features/home/presentation/screens/home_viewmodel.dart';

class HomeSearchBar extends StatefulWidget {
  final HomeViewModel vm;
  final SearchType selectedType;
  final TextEditingController controller;
  final VoidCallback onClear;
  final Function(String) onSubmitted;
  final VoidCallback? onDisabledTap; // 📍 추가: 비활성화 상태에서 클릭 시 호출

  const HomeSearchBar({
    super.key,
    required this.vm,
    required this.selectedType,
    required this.controller,
    required this.onClear,
    required this.onSubmitted,
    this.onDisabledTap,
  });

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> with TickerProviderStateMixin {
  late AnimationController _borderAnimationController;
  late Animation<double> _borderAnimation;
  
  // 📍 쉐이크 & 경고 애니메이션을 위한 컨트롤러
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  double _buttonScale = 1.0;
  bool _isWarning = false; // 빨간색 보더 상태 관리

  @override
  void initState() {
    super.initState();
    // 기존 테두리 애니메이션
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderAnimationController, curve: Curves.easeInOut),
    );

    // 📍 쉐이크 애니메이션 설정 (좌우로 4번 흔들림)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(HomeSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedType != oldWidget.selectedType && widget.selectedType != SearchType.none) {
      _borderAnimationController.forward(from: 0.0);
    } else if (widget.selectedType == SearchType.none) {
      _borderAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // 📍 비활성화 클릭 시 경고 액션 실행
  void _triggerWarning() {
    HapticFeedback.vibrate(); // 강력한 진동으로 경고
    widget.onDisabledTap?.call(); // 외부(버튼 통통 튀기 등) 콜백 호출
    
    setState(() => _isWarning = true);
    _shakeController.forward(from: 0.0);
    
    // 600ms 후 다시 원래 색상으로 복구
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isWarning = false);
    });
  }

  void _handleTap() {
    if (widget.controller.text.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _buttonScale = 0.92);
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() => _buttonScale = 1.0);
          widget.onSubmitted(widget.controller.text);
        }
      });
    } else if (widget.selectedType == SearchType.none) {
      _triggerWarning(); // 📍 글자가 없고 타입도 없을 때 실행
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, child) {
        
        final bool hasType = widget.vm.selectedType != SearchType.none;
        final bool hasText = widget.controller.text.isNotEmpty;
        final Color activeColor = widget.vm.selectedType == SearchType.ingredients 
            ? AppColors.primaryGreen 
            : AppColors.primaryOrange;

        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, 
            
            // 👆 [기존] 빈 공간 터치 시 포커스
            onTap: () {
              if (!hasType) {
                 _triggerWarning();
              } else {
                 FocusScope.of(context).requestFocus(widget.vm.searchFocusNode);
              }
            },

            // ✨ [신규] 텍스트가 있을 때 길게 누르면 -> 즉시 칩으로 변환!
            onLongPress: () {
              // 1. 텍스트가 있고 & 재료 모드일 때만 동작
              if (hasText && widget.vm.selectedType == SearchType.ingredients) {
                HapticFeedback.mediumImpact(); // '톡' 하는 진동 피드백
                
                // 2. 현재 입력된 텍스트를 칩으로 추가 (ViewModel이 알아서 텍스트 지워줌)
                widget.vm.addIngredient(widget.controller.text);
              }
            },

            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. 테두리
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _borderAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: BorderPainter(
                          progress: _borderAnimation.value,
                          color: _isWarning 
                              ? Colors.redAccent 
                              : (hasType ? activeColor : Colors.transparent),
                        ),
                      );
                    },
                  ),
                ),
                
                // 2. 검색바 본체
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  constraints: const BoxConstraints(
                    minHeight: 54,
                    maxHeight: 250,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isWarning 
                          ? Colors.redAccent.withValues(alpha: 0.5) 
                          : Colors.grey.withValues(alpha: 0.1),
                      width: _isWarning ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.search, 
                        color: _isWarning 
                            ? Colors.redAccent 
                            : (hasType ? activeColor : AppColors.textGrey), 
                        size: 20
                      ),
                      const SizedBox(width: 8),
                      
                      // 태그 + 입력창
                      Expanded(
                        child: IgnorePointer(
                          ignoring: !hasType,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...widget.vm.selectedIngredients.map((ingredient) => AnimatedTag(
                                    key: ValueKey(ingredient),
                                    label: ingredient,
                                    color: activeColor,
                                    onRemove: () => widget.vm.removeIngredient(ingredient),
                                  )),

                              IntrinsicWidth(
                                child: ConstrainedBox(
                                  // 아까 설정한 가변 너비 로직 유지 (태그 유무에 따라 150 <-> 60)
                                  constraints: BoxConstraints(
                                    minWidth: widget.vm.selectedIngredients.isEmpty ? 150.0 : 60.0
                                  ), 
                                  child: TextField(
                                    controller: widget.controller,
                                    focusNode: widget.vm.searchFocusNode,
                                    enabled: hasType,
                                    onChanged: (value) {
                                      widget.vm.onSearchTextChanged(value);
                                      setState(() {}); 
                                    },
                                    onSubmitted: widget.onSubmitted,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'Pretendard',
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: widget.vm.selectedIngredients.isEmpty 
                                          ? (!hasType ? "모드를 선택해주세요" : "재료를 입력해주세요")
                                          : "",
                                      hintStyle: TextStyle(
                                        color: _isWarning ? Colors.redAccent : AppColors.textGrey,
                                        fontSize: 14,
                                        fontWeight: _isWarning ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8), 
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      // 우측 버튼들
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: hasText ? 1.0 : 0.0,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close, size: 18, color: AppColors.textGrey),
                                onPressed: hasText ? widget.onClear : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTapDown: (_) => hasText ? setState(() => _buttonScale = 0.92) : null,
                            onTapCancel: () => setState(() => _buttonScale = 1.0),
                            onTap: _handleTap,
                            child: AnimatedScale(
                              scale: _buttonScale,
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeInOut,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: hasText 
                                      ? activeColor 
                                      : (_isWarning 
                                          ? Colors.redAccent.withValues(alpha: 0.2) 
                                          : Colors.grey.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded, 
                                  color: Colors.white, 
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  BorderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (progress <= 0 || color == Colors.transparent) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    
    final metric = metrics.first;
    final double totalLength = metric.length;
    
    double bottomCenter = totalLength * 0.75; 
    double halfProgressLength = (totalLength * 0.5) * progress;

    double leftStart = bottomCenter - halfProgressLength;
    _drawPathSegment(canvas, metric, leftStart, bottomCenter, paint, totalLength);

    double rightEnd = bottomCenter + halfProgressLength;
    _drawPathSegment(canvas, metric, bottomCenter, rightEnd, paint, totalLength);
  }

  void _drawPathSegment(Canvas canvas, PathMetric metric, double start, double end, Paint paint, double total) {
    if (start < 0) {
      canvas.drawPath(metric.extractPath(total + start, total), paint);
      canvas.drawPath(metric.extractPath(0, end), paint);
    } else if (end > total) {
      canvas.drawPath(metric.extractPath(start, total), paint);
      canvas.drawPath(metric.extractPath(0, end % total), paint);
    } else {
      canvas.drawPath(metric.extractPath(start, end), paint);
    }
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// 📍 태그 생성/삭제 애니메이션을 담당하는 위젯
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
    // 📍 생성 애니메이션: 0.0 -> 1.0 (커짐)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // 📍 easeOutBack: 약간 커졌다가 줄어드는 "블록 생성" 느낌의 탄성 효과
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

  // 📍 삭제 버튼 클릭 시: 작아지는 애니메이션 후 실제 데이터 삭제
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
              onTap: _handleRemove, // 📍 애니메이션 실행 후 삭제
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