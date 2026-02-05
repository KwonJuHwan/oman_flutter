import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;

// -----------------------------------------------------------------------------
// 1. 영상 데이터 모델
// -----------------------------------------------------------------------------
class YoutubeVideo {
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String views;
  final String publishedAt;

  YoutubeVideo({
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.views,
    required this.publishedAt,
  });
}

// -----------------------------------------------------------------------------
// 2. 메인 위젯
// -----------------------------------------------------------------------------
class YoutubeRecommendationLayer extends StatefulWidget {
  final VoidCallback onClose; 

  const YoutubeRecommendationLayer({super.key, required this.onClose});

  @override
  State<YoutubeRecommendationLayer> createState() =>
      _YoutubeRecommendationLayerState();
}

class _YoutubeRecommendationLayerState extends State<YoutubeRecommendationLayer>
    with TickerProviderStateMixin { 
  
  // 1. 슬라이드(이동) 컨트롤러
  late AnimationController _slideController;
  late Animation<double> _slideCurve; 
  
  // 2. 뿅(Pop) 컨트롤러 (등장/퇴장용)
  late AnimationController _popController;
  late Animation<double> _popAnimation;

  // 3. ✨ 펄싱 글로우(숨쉬기) 컨트롤러
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

  // 더미 데이터
  final _bestMatch = YoutubeVideo(title: "백종원의 김치찌개, 이것만 알면 끝!", channelName: "백종원의 요리비책", thumbnailUrl: "assets/images/kimchi_stew_thumb.jpg", views: "조회수 500만회", publishedAt: "2년 전");
  final List<YoutubeVideo> _popularVideos = List.generate(5, (index) => YoutubeVideo(title: "초간단 5분 김치찌개 레시피 (자취생 필수)", channelName: "자취요리왕", thumbnailUrl: "assets/images/thumb_$index.jpg", views: "조회수 ${10 + index}만회", publishedAt: "${index + 1}개월 전"));

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
    
    // -------------------------------------------------------------------------
    // A. 슬라이드 애니메이션 (물리 액션)
    // -------------------------------------------------------------------------
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 양방향 오버슈트 (화면 밖으로 나갔다 돌아오기)
    _slideCurve = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutBack, 
    );

    // -------------------------------------------------------------------------
    // B. 팝 애니메이션 (등장/퇴장)
    // -------------------------------------------------------------------------
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _popAnimation = CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut, 
      reverseCurve: Curves.easeInBack, 
    );

    // -------------------------------------------------------------------------
    // C. ✨ 펄싱 애니메이션 (수정 모드 글로우 - 수정됨)
    // -------------------------------------------------------------------------
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // 속도 약간 빠르게
    );

    // ✨ [수정] 범위를 0~8에서 0~15로 대폭 늘림 (확실하게 보이도록)
    _pulseAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // --- 초기 실행 시퀀스 ---
    _popController.forward();   
    _slideController.forward(); 

    // 콘텐츠 페이드인
    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _popController.dispose();
    _pulseController.dispose(); 
    super.dispose();
  }

  // 화면 열기/닫기 토글
  void _toggleScreen() {
    if (_isEditMode) return; 

    if (_slideController.isCompleted) {
      _slideController.reverse(); 
    } else {
      _slideController.forward(); 
    }
  }

  // 삭제 로직
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

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    const double buttonSize = 60.0; 

    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _popController, _pulseController]),
      builder: (context, child) {
        
        // 1. 위치 계산
        double slideValue = _slideCurve.value;
        double startX = screenSize.width - buttonSize; 
        double endX = 0; 
        
        double currentButtonX = startX - ((startX - endX) * slideValue);

        double panelX;
        if (slideValue <= 0.0) {
          panelX = screenSize.width; 
        } else {
          panelX = math.max(0, currentButtonX);
        }

        // 2. 색상 결정
        Color currentColor;
        bool showPlayIconLeft;
        
        if (_slideController.value > 0.95) {
          currentColor = _white; 
          showPlayIconLeft = false;
        } else if (_slideController.value < 0.05) {
          currentColor = _darkGrey; 
          showPlayIconLeft = true;
        } else {
          if (_slideController.status == AnimationStatus.forward) {
            currentColor = _darkGrey;
            showPlayIconLeft = true;
          } else {
            currentColor = _white;
            showPlayIconLeft = false;
          }
        }

        return Stack(
          children: [
            // 1. 메인 패널 (화면)
            Positioned(
              top: 0, bottom: 0,
              left: panelX, 
              width: screenSize.width, 
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


            // 0. 수정 모드 배경 탭 (해제용)
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

  
            
            // 2. 동글동글 슬라임 버튼
            Positioned(
              top: _dragY - (buttonSize / 2),
              left: currentButtonX,
              child: GestureDetector(
                onTap: _toggleScreen,
                
                // 꾹 누르면 수정 모드 + 펄싱 시작
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
                              width: buttonSize,
                              height: buttonSize,
                              decoration: BoxDecoration(
                                color: currentColor,
                                shape: BoxShape.circle,
                                // ✨ [핵심 수정] 펄싱 글로우 강화
                                boxShadow: [
                                  // 기본 그림자
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                  // ✨ 펄싱 글로우 (수정 모드일 때만)
                                  if (_isEditMode)
                                    BoxShadow(
                                      // ✨ 노란색(Gold/Yellow)으로 변경하여 배경 상관없이 잘 보이게 함
                                      color: Colors.blueGrey.withOpacity(0.6), 
                                      blurRadius: 15 + _pulseAnimation.value, // 더 넓게 퍼짐
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
                                  child: const Icon(
                                    Icons.play_arrow_rounded, 
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                  
                            // 삭제(X) 버튼
                            if (_isEditMode)
                              Positioned(
                                top: -5,
                                right: -5,
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
  
  // (하위 위젯: 변경 없음)
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Best Match", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Pretendard', color: Colors.white)), const SizedBox(height: 16), _buildBestMatchCard(), const SizedBox(height: 32),
          const Text("Popular", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Pretendard', color: Colors.white)), const SizedBox(height: 16),
          ListView.separated(padding: EdgeInsets.zero, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _popularVideos.length, separatorBuilder: (context, index) => const SizedBox(height: 16), itemBuilder: (context, index) => _buildPopularItem(_popularVideos[index])),
        ]),
    );
  }

  Widget _buildBestMatchCard() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(20), image: const DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover)),
          child: Stack(children: [Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)), child: Text("#Best Pick", style: TextStyle(color: _youtubeRed, fontWeight: FontWeight.bold, fontSize: 12))))]),
        ), const SizedBox(height: 12), const Text("백종원의 김치찌개, 이것만 알면 끝!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text("${_bestMatch.channelName} • ${_bestMatch.views}", style: TextStyle(fontSize: 14, color: Colors.grey[400])),
      ]);
  }

  Widget _buildPopularItem(YoutubeVideo video) {
    return Row(children: [
        Container(width: 100, height: 70, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12), image: const DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover))), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(video.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _youtubeRed.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text("#Yummy", style: TextStyle(fontSize: 10, color: _youtubeRed, fontWeight: FontWeight.bold))), const SizedBox(width: 6), Text(video.channelName, style: TextStyle(fontSize: 12, color: Colors.grey[400]))])])),
      ]);
  }
}