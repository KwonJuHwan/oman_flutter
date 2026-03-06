import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/enums/search_type.dart';
import '../../state/home_viewmodel.dart';
import 'border_painter.dart'; // 추가
import 'animated_tag.dart'; // 추가

class HomeSearchBar extends StatefulWidget {
  final HomeViewModel vm;
  final SearchType selectedType;
  final TextEditingController controller;
  final VoidCallback onClear;
  final Function(String) onSubmitted;
  final VoidCallback? onDisabledTap; 

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
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  double _buttonScale = 1.0;
  bool _isWarning = false;

  @override
  void initState() {
    super.initState();
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderAnimationController, curve: Curves.easeInOut),
    );

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

  void _triggerWarning() {
    HapticFeedback.vibrate();
    widget.onDisabledTap?.call(); 
    
    setState(() => _isWarning = true);
    _shakeController.forward(from: 0.0);
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isWarning = false);
    });
  }

  void _handleTap() {
    final bool isIngredientMode = widget.vm.selectedType == SearchType.ingredients;
    final bool hasChips = widget.vm.selectedIngredients.isNotEmpty;
    final bool hasText = widget.controller.text.isNotEmpty;

    bool canSearch = isIngredientMode ? hasChips : hasText;

    if (canSearch) {
      HapticFeedback.lightImpact();
      setState(() => _buttonScale = 0.92);
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() => _buttonScale = 1.0);
          widget.onSubmitted(widget.controller.text);
        }
      });
    } else if (widget.selectedType == SearchType.none || !canSearch) {
      _triggerWarning(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, child) {
        final bool hasType = widget.vm.selectedType != SearchType.none;
        final bool hasText = widget.controller.text.isNotEmpty;
        final bool hasChips = widget.vm.selectedIngredients.isNotEmpty;
        bool isSearchEnabled = false;
        
        if (widget.vm.selectedType == SearchType.ingredients) {
          isSearchEnabled = hasChips;
        } else if (widget.vm.selectedType == SearchType.recipe) {
          isSearchEnabled = hasText; 
        }
        
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
            onTap: () {
              if (!hasType) {
                 _triggerWarning();
              } else {
                 FocusScope.of(context).requestFocus(widget.vm.searchFocusNode);
              }
            },
            onLongPress: () {
              if (hasText && widget.vm.selectedType == SearchType.ingredients) {
                final text = widget.controller.text;
                final matchedDto = widget.vm.filteredCandidates.where((e) => e.name == text).firstOrNull;
                
                if (matchedDto != null) {
                  HapticFeedback.mediumImpact();
                  widget.vm.addIngredient(matchedDto);
                } else {
                  _triggerWarning(); 
                }
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                      
                      Expanded(
                        child: IgnorePointer(
                          ignoring: !hasType,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...widget.vm.selectedIngredients.map((ingredient) => AnimatedTag(
                                    key: ValueKey(ingredient.id), 
                                    label: ingredient.name,
                                    color: AppColors.primaryGreen,
                                    onRemove: () => widget.vm.removeIngredient(ingredient),
                                  )),

                              IntrinsicWidth(
                                child: ConstrainedBox(
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
                                          ? (!hasType 
                                              ? "모드를 선택해주세요" 
                                              : (widget.vm.selectedType == SearchType.ingredients 
                                                  ? "재료를 입력해주세요" 
                                                  : "음식을 입력해주세요"))
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
                                  color: isSearchEnabled 
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