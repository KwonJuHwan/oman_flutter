import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;

import '../../../domain/models/video_recommendation_model.dart'; 
import '../../../domain/repositories/recipe_repository.dart'; 
import 'youtube_video_card.dart'; 

class YoutubeRecommendationLayer extends StatefulWidget {
  final RecipeRepository repository; 
  final VoidCallback onClose;
  final String culinaryName; 
  final List<int> ingredientIds; 

  const YoutubeRecommendationLayer({
    super.key, 
    required this.repository,
    required this.onClose,
    required this.culinaryName,
    required this.ingredientIds,
  });

  @override
  State<YoutubeRecommendationLayer> createState() => _YoutubeRecommendationLayerState();
}

class _YoutubeRecommendationLayerState extends State<YoutubeRecommendationLayer> with TickerProviderStateMixin { 
  late AnimationController _slideController;
  late Animation<double> _slideCurve; 
  late AnimationController _popController;
  late Animation<double> _popAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _contentOpacityAnimation;

  bool _isLoading = true;
  double _dragY = 0.0;
  bool _isInitialized = false;
  bool _isEditMode = false;
  bool _isDragging = false;

  final Color _darkGrey = const Color(0xFF333333);
  final Color _youtubeRed = const Color(0xFFFF4E45);
  final Color _white = Colors.white;

  VideoRecommendationResponseDto? _videoData;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final Size screenSize = MediaQuery.of(context).size;
      _dragY = screenSize.height / 2;
      _isInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // ✨ Dio 생성 코드는 완전히 삭제되었습니다! 주입받은 widget.repository를 바로 사용합니다.
    
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideCurve = CurvedAnimation(parent: _slideController, curve: Curves.easeInOutBack); 

    _popController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _popAnimation = CurvedAnimation(parent: _popController, curve: Curves.elasticOut, reverseCurve: Curves.easeInBack); 

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _popController.forward();   
    _slideController.forward(); 

    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: const Interval(0.7, 1.0, curve: Curves.easeIn)),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });

    _fetchVideoData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _popController.dispose();
    _pulseController.dispose(); 
    super.dispose();
  }

  void _toggleScreen() {
    if (_isEditMode) return; 
    if (_slideController.isCompleted) {
      _slideController.reverse(); 
    } else {
      _slideController.forward(); 
    }
  }

  Future<void> _handleDelete() async {
    HapticFeedback.mediumImpact();
    _pulseController.stop(); 
    setState(() => _isEditMode = false);
    await _popController.reverse();
    widget.onClose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isEditMode) return;
    final Size screenSize = MediaQuery.of(context).size;
    setState(() {
      _isDragging = true;
      _dragY += details.delta.dy;
      _dragY = _dragY.clamp(100.0, screenSize.height - 100.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
  }

  Future<void> _fetchVideoData() async {
    final data = await widget.repository.getRecommendedVideos( // ✨ widget.repository 사용
      culinaryName: widget.culinaryName,
      ingredientIds: widget.ingredientIds,
    );

    if (mounted) {
      setState(() {
        _videoData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    const double buttonSize = 60.0; 

    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _popController, _pulseController]),
      builder: (context, child) {
        double slideValue = _slideCurve.value;
        double startX = screenSize.width - buttonSize; 
        double currentButtonX = startX - ((startX - 0) * slideValue);
        double panelX = slideValue <= 0.0 ? screenSize.width : math.max(0, currentButtonX);

        Color currentColor;
        bool showPlayIconLeft;
        
        if (_slideController.value > 0.95) {
          currentColor = _white; 
          showPlayIconLeft = false;
        } else if (_slideController.value < 0.05) {
          currentColor = _darkGrey; 
          showPlayIconLeft = true;
        } else {
          currentColor = _slideController.status == AnimationStatus.forward ? _darkGrey : _white;
          showPlayIconLeft = _slideController.status == AnimationStatus.forward;
        }

        return Stack(
          children: [
            Positioned(
              top: 0, bottom: 0, left: panelX, width: screenSize.width, 
              child: Container(
                color: _darkGrey,
                child: Stack(
                  children: [
                    if (_slideController.value > 0.6)
                      Positioned.fill(
                        child: Opacity(
                          opacity: _contentOpacityAnimation.value,
                          child: _isLoading ? _buildLoadingSkeleton() : _buildContent(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_isEditMode)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isEditMode = false);
                    _pulseController.reset(); 
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
            Positioned(
              top: _dragY - (buttonSize / 2),
              left: currentButtonX,
              child: GestureDetector(
                onTap: _toggleScreen,
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _isEditMode = true);
                  _pulseController.repeat(reverse: true); 
                },
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: ScaleTransition(
                  scale: _popAnimation,
                  child: Builder(
                    builder: (context) {
                      double editScale = _isEditMode ? 1.1 : 1.0;
                      return Transform.scale(
                        scaleX: editScale * (1.0 + (_slideController.isAnimating ? 0.1 : 0.0)),
                        scaleY: editScale * (1.0 - (_slideController.isAnimating ? 0.05 : 0.0)),
                        child: Stack(
                          clipBehavior: Clip.none, 
                          children: [
                            Container(
                              width: buttonSize, height: buttonSize,
                              decoration: BoxDecoration(
                                color: currentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3), // ✨ withOpacity 대체
                                    blurRadius: 10, offset: const Offset(0, 4),
                                  ),
                                  if (_isEditMode)
                                    BoxShadow(
                                      color: Colors.blueGrey.withValues(alpha: 0.6), // ✨ withOpacity 대체
                                      blurRadius: 15 + _pulseAnimation.value, 
                                      spreadRadius: _pulseAnimation.value,
                                    ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: _isDragging ? Colors.grey[600] : _youtubeRed,
                                  shape: BoxShape.circle,
                                ),
                                child: Transform.rotate(
                                  angle: showPlayIconLeft ? math.pi : 0,
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                            if (_isEditMode)
                              Positioned(
                                top: -5, right: -5,
                                child: GestureDetector(
                                  onTap: _handleDelete,
                                  child: Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!, highlightColor: Colors.grey[700]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 150, height: 24, color: Colors.white), const SizedBox(height: 16),
            Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 12), Container(width: 200, height: 20, color: Colors.white),
            const SizedBox(height: 32), Container(width: 100, height: 22, color: Colors.white), const SizedBox(height: 16),
            ...List.generate(3, (index) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [Container(width: 100, height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: double.infinity, height: 16, color: Colors.white), const SizedBox(height: 8), Container(width: 100, height: 12, color: Colors.white)]))]))),
          ]),
      ),
    );
  }

  Widget _buildContent() {
    if (_videoData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 100),
          child: Text("데이터를 불러오지 못했습니다.", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final matchVideos = _videoData!.matchVideos;
    final popularVideos = _videoData!.popularVideos;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), 
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          const Text("Best Match", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), 
          const SizedBox(height: 16), 
          
          if (matchVideos.isNotEmpty)
            YoutubeBestMatchCard(video: matchVideos.first) 
          else
            const Text("매칭된 영상이 없습니다.", style: TextStyle(color: Colors.grey)),
            
          const SizedBox(height: 32),
          const Text("Popular", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), 
          const SizedBox(height: 16),
          
          if (popularVideos.isNotEmpty)
            ListView.separated(
              padding: EdgeInsets.zero, 
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(), 
              itemCount: popularVideos.length, 
              separatorBuilder: (context, index) => const SizedBox(height: 16), 
              itemBuilder: (context, index) => YoutubePopularItem(video: popularVideos[index]), 
            )
          else
            const Text("인기 영상이 없습니다.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}