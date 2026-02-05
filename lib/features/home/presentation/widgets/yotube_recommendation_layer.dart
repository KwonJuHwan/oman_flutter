import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  late Animation<double> _contentOpacityAnimation;
  late Animation<double> _slideCurve; // 위치 이동 곡선

  bool _isLoading = true;
  double _dragY = 0.0;
  bool _isInitialized = false;
  bool _isDragging = false;

  // ✨ 컬러 정의
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // ✨ [핵심 수정 2] 양방향 쫀득함 구현
    // Forward (Right->Left): EaseInExpo (느리게 출발 -> 획 이동)
    // Reverse (Left->Right): EaseOutExpo (느리게 출발 -> 획 이동)
    // * Reverse 애니메이션은 1.0 -> 0.0으로 진행되므로, EaseOut을 써야 
    //   '높은 값(1.0)'에 오래 머물다가 '0.0'으로 뚝 떨어지는 효과(Snap)가 납니다.
    _slideCurve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInExpo, 
      reverseCurve: Curves.easeOutExpo, 
    );

    // 콘텐츠 페이드인
    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleScreen() {
    if (_controller.isCompleted) {
      _controller.reverse(); 
    } else {
      _controller.forward();
    }
  }

  void _closeLayer() {
    if (!_controller.isDismissed) {
      _controller.reverse().then((_) => widget.onClose());
    } else {
      widget.onClose();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_controller.value > 0.1) return;
    final Size screenSize = MediaQuery.of(context).size;
    setState(() {
      _dragY += details.delta.dy;
      _dragY = _dragY.clamp(100.0, screenSize.height - 100.0);
      _isDragging = true;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
    // UI 상수
    const double stripWidth = 20.0;
    const double baseProtrusion = 30.0; 
    const double baseTabHeight = 80.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        
        // 1. 위치 계산 (양방향 Snap 적용됨)
        double currentX = (screenSize.width - stripWidth) * (1 - _slideCurve.value);
        
        // 2. ✨ [핵심 수정 1] 색상 변경 (No Gradient)
        // 50% 지점에서 딱! 바뀝니다. (테두리가 쫀득하게 늘어난 절정의 순간)
        Color currentStripColor;

        if (_controller.status == AnimationStatus.reverse) {
          // ✨ 유튜브 -> 검색 화면으로 돌아갈 때: 
          // 거의 다 도착할 때(0.1)까지 흰색을 유지하다가 마지막에 회색으로 변경
          currentStripColor = _controller.value > 0.1 ? _white : _darkGrey;
        } else if (_controller.status == AnimationStatus.forward) {
          // ✨ 검색 -> 유튜브 화면으로 갈 때: 
          // 쫀득하게 늘어나는 정점(0.5)을 지난 후에 흰색으로 변경
          currentStripColor = _controller.value > 0.9 ? _white : _darkGrey;
        } else {
          // 애니메이션이 멈춰있을 때의 기본 처리
          currentStripColor = _controller.value > 0.5 ? _white : _darkGrey;
        }
        
        // 3. 방향 결정
        // 실제 위치(_slideCurve)가 화면 절반을 넘었는지로 판단
        bool isRightSide = _slideCurve.value < 0.5;

        double deformationFactor = math.pow(math.sin(_controller.value * math.pi), 0.6).toDouble();
        double currentProtrusion = baseProtrusion + (deformationFactor * 140.0);
        double currentTabHeight = baseTabHeight + (deformationFactor * 180.0);
        // double deformationFactor = math.sin(_controller.value * math.pi);
        // double currentProtrusion = baseProtrusion + (deformationFactor * 100.0);
        // double currentTabHeight = baseTabHeight + (deformationFactor * 60.0);

        return Stack(
          children: [
            // 1. 메인 패널
            Positioned(
              top: 0, bottom: 0,
              left: currentX + stripWidth, 
              width: screenSize.width - stripWidth,
              child: Container(
                color: _darkGrey,
                child: Stack(
                  children: [
                    if (_controller.value > 0.8)
                      Positioned.fill(
                        child: Opacity(
                          opacity: _contentOpacityAnimation.value,
                          child: _isLoading ? _buildLoadingSkeleton() : _buildContent(),
                        ),
                      ),
                    if (_controller.value > 0.8)
                       Positioned(
                        top: 50, right: 20,
                        child: GestureDetector(
                          onTap: _toggleScreen,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 24, color: Colors.white),
                          ),
                        ),
                       ),
                  ],
                ),
              ),
            ),

            // 2. 일체형 탭 & 테두리
            Positioned(
              top: 0, bottom: 0,
              left: isRightSide 
                  ? currentX - currentProtrusion 
                  : currentX,
              width: stripWidth + currentProtrusion,
              child: CustomPaint(
                painter: LiquidTabPainter(
                  color: currentStripColor,
                  tabY: _dragY,
                  stripWidth: stripWidth,
                  protrusion: currentProtrusion,
                  tabHeight: currentTabHeight,
                  isRightSide: isRightSide,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: _dragY - 14,
                      left: isRightSide 
                          ? 5.0 
                          : stripWidth + currentProtrusion - 33.0,
                      child: GestureDetector(
                        onTap: _toggleScreen,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: _isDragging ? Colors.grey[800] : _youtubeRed,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Icon(
                            isRightSide ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 3. X 버튼
            if (_controller.value < 0.1 && !_isDragging)
              Positioned(
                top: _dragY - currentTabHeight/2 - 15,
                right: 10,
                child: GestureDetector(
                  onTap: _closeLayer,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.black, size: 12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // (하위 위젯들: _buildLoadingSkeleton, _buildContent 등은 기존 코드와 동일)
  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 24, color: Colors.white),
            const SizedBox(height: 16),
            Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 12),
            Container(width: 200, height: 20, color: Colors.white),
            const SizedBox(height: 32),
            Container(width: 100, height: 22, color: Colors.white),
            const SizedBox(height: 16),
            ...List.generate(3, (index) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [Container(width: 100, height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: double.infinity, height: 16, color: Colors.white), const SizedBox(height: 8), Container(width: 100, height: 12, color: Colors.white)]))]))),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Best Match", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Pretendard', color: Colors.white)),
          const SizedBox(height: 16),
          _buildBestMatchCard(),
          const SizedBox(height: 32),
          const Text("Popular", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Pretendard', color: Colors.white)),
          const SizedBox(height: 16),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _popularVideos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildPopularItem(_popularVideos[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildBestMatchCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200, width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(20), image: const DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover)),
          child: Stack(children: [Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)), child: Text("#Best Pick", style: TextStyle(color: _youtubeRed, fontWeight: FontWeight.bold, fontSize: 12))))]),
        ),
        const SizedBox(height: 12),
        const Text("백종원의 김치찌개, 이것만 알면 끝!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text("${_bestMatch.channelName} • ${_bestMatch.views}", style: TextStyle(fontSize: 14, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildPopularItem(YoutubeVideo video) {
    return Row(
      children: [
        Container(width: 100, height: 70, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12), image: const DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(video.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _youtubeRed.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text("#Yummy", style: TextStyle(fontSize: 10, color: _youtubeRed, fontWeight: FontWeight.bold))), const SizedBox(width: 6), Text(video.channelName, style: TextStyle(fontSize: 12, color: Colors.grey[400]))])])),
      ],
    );
  }
}

// ✨ [Painter 유지]
class LiquidTabPainter extends CustomPainter {
  final Color color;
  final double tabY;
  final double stripWidth;
  final double protrusion;
  final double tabHeight;
  final bool isRightSide;

  LiquidTabPainter({
    required this.color,
    required this.tabY,
    required this.stripWidth,
    required this.protrusion,
    required this.tabHeight,
    required this.isRightSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final path = Path();
    final edgePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    double stripEdgeX = isRightSide ? protrusion : stripWidth; 
    double bulgeTipX = isRightSide ? 0 : stripWidth + protrusion;
    double backEdgeX = isRightSide ? stripWidth + protrusion : 0;

    path.moveTo(stripEdgeX, 0);
    path.lineTo(stripEdgeX, tabY - tabHeight / 2);

    path.cubicTo(
      stripEdgeX, tabY - tabHeight / 3, // 제어점 1: 테두리쪽에서 완만하게 시작
      bulgeTipX, tabY - tabHeight / 3,  // 제어점 2: 정점쪽으로 넓게 붙음
      bulgeTipX, tabY                   // 도착점: 탭의 가장 튀어나온 끝부분
    );

    path.cubicTo(
      bulgeTipX, tabY + tabHeight / 3,  // 제어점 3: 정점에서 넓게 시작
      stripEdgeX, tabY + tabHeight / 3, // 제어점 4: 테두리쪽으로 완만하게 복귀
      stripEdgeX, tabY + tabHeight / 2  // 도착점
    );

    // path.cubicTo(stripEdgeX, tabY - tabHeight / 4, bulgeTipX, tabY - tabHeight / 4, bulgeTipX, tabY);
    // path.cubicTo(bulgeTipX, tabY + tabHeight / 4, stripEdgeX, tabY + tabHeight / 4, stripEdgeX, tabY + tabHeight / 2);

    path.lineTo(stripEdgeX, size.height);
    path.lineTo(backEdgeX, size.height);
    path.lineTo(backEdgeX, 0);
    path.close();

    if (isRightSide) {
      canvas.drawPath(path.shift(const Offset(-1, 0)), shadowPaint);
    }
    canvas.drawPath(path, paint);
    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant LiquidTabPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.tabY != tabY ||
           oldDelegate.protrusion != protrusion ||
           oldDelegate.tabHeight != tabHeight ||
           oldDelegate.isRightSide != isRightSide;
  }
}