import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:oman_fe/features/home/domain/enums/search_type.dart';
import '../widgets/animations/bounce_wrapper.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_category_button.dart';
import '../widgets/recipe_report_sheet.dart';
import 'home_viewmodel.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeViewModel _vm = HomeViewModel();
  final GlobalKey<SequentialBounceWrapperState> _leftKey = GlobalKey();
  final GlobalKey<SequentialBounceWrapperState> _rightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // ViewModel의 변화를 감지하여 UI 리빌드
    _vm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double sheetHeight = screenHeight * 0.7;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 백그라운드 "Pulse Glow" (화면 끝까지 물들임)
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            width: screenWidth,
            height: screenHeight,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [
                  Colors.transparent,
                  _vm.glowColor, // ViewModel에서 withValues(alpha: 0.5) 처리됨
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          // 2. 배경 터치 영역
          GestureDetector(
            onTap: () => _vm.setResultVisible(false),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),

          // 3. 상단 메인 UI (SafeArea로 상태바 보호)
          SafeArea(
            bottom: false, 
            child: Stack(
              children: [
                _buildMainUI(screenHeight),
              ],
            ),
          ),

          // 4. 결과 레이어 (SafeArea 밖으로 배치하여 바닥에 밀착)
          _buildResultLayer(sheetHeight),
        ],
      ),
    );
  }

  Widget _buildMainUI(double screenHeight) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
      top: _vm.isResultVisible ? 40 : screenHeight * 0.22,
      left: 24, right: 24,
      child: Column(
        children: [
          Image.asset('assets/images/logo.png', width: 220),
          const SizedBox(height: 40),
          HomeSearchBar(
            vm: _vm,
            selectedType: _vm.selectedType,
            controller: _vm.searchController,
            onClear: _vm.resetSearch,
            onSubmitted: _vm.submitSearch,
            onDisabledTap: () {
              _leftKey.currentState?.play();
              _rightKey.currentState?.play();
            },
          ),
          _buildSearchSuggestions(),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SequentialBounceWrapper(
                key: _leftKey, isLeft: true,
                child: HomeCategoryButton(
                  type: SearchType.ingredients, label: "재료", icon: Icons.eco_rounded,
                  baseColor: AppColors.primaryGreen,
                  isSelected: _vm.selectedType == SearchType.ingredients,
                  onTap: () => _vm.toggleType(SearchType.ingredients),
                ),
              ),
              const SizedBox(width: 12),
              SequentialBounceWrapper(
                key: _rightKey, isLeft: false,
                child: HomeCategoryButton(
                  type: SearchType.recipe, label: "요리", icon: Icons.soup_kitchen_rounded,
                  baseColor: AppColors.primaryOrange,
                  isSelected: _vm.selectedType == SearchType.recipe,
                  onTap: () => _vm.toggleType(SearchType.recipe),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultLayer(double sheetHeight) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutQuart,
      bottom: _vm.isResultVisible ? 0 : -(sheetHeight - 80.0),
      left: 0, right: 0, height: sheetHeight,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -5) _vm.setResultVisible(true);
          if (details.delta.dy > 5) _vm.setResultVisible(false);
        },
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            RecipeReportSheet(
              isLoading: _vm.isModalLoading,
              isResultVisible: _vm.isRealDataLoaded,
              onSelectionChanged: _vm.updateSelection,
            ),
            
            // 📍 누락되었던 플로팅 버튼 레이어 메서드 호출
            _buildFloatingButtonLayer(),
          ],
        ),
      ),
    );
  }

  // 📍 플로팅 버튼 애니메이션 레이어
  Widget _buildFloatingButtonLayer() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      top: _vm.finalButtonVisible ? -25 : 80,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 400),
        scale: _vm.finalButtonVisible ? 1.0 : 0.0,
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _vm.finalButtonVisible ? 1.0 : 0.0,
          child: _buildFloatingButtonContent(),
        ),
      ),
    );
  }

  // 📍 플로팅 버튼 실제 디자인 (withValues 적용)
  Widget _buildFloatingButtonContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), // withValues 사용
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            "이 재료로 다른 요리 찾기",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }


Widget _buildSearchSuggestions() {
  final bool showSection = _vm.selectedType == SearchType.ingredients;
  final bool hasRecommendations = _vm.searchController.text.isNotEmpty && _vm.filteredCandidates.isNotEmpty;

  return AnimatedSize(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutQuart,
    child: showSection
        ? Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 📍 [섹션 A] 추천 재료 (조건부 노출 + 밀어내기 애니메이션)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack, // 팅~ 하고 나오는 느낌
                  child: hasRecommendations
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "추천 재료",
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: AppColors.primaryGreen // 강조 색상
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _vm.filteredCandidates
                                  .map((name) => _buildSuggestionChip(name, isRecommended: true))
                                  .toList(),
                            ),
                            // 구분선 (추천과 최근 사이)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(), // 없을 땐 공간 차지 안 함
                ),

                // 📍 [섹션 B] 최근 검색어 (항상 존재, 추천이 나오면 아래로 밀림)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "최근 검색한 재료",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    _vm.recentSearches.isEmpty
                        ? const Text("최근 검색 기록이 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 13))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _vm.recentSearches
                                .map((name) => _buildSuggestionChip(name, isRecommended: false))
                                .toList(),
                          ),
                  ],
                ),
              ],
            ),
          )
        : const SizedBox.shrink(),
  );
}

// 📍 [수정] 칩 디자인 (추천 여부에 따라 색상 미세 조정)
Widget _buildSuggestionChip(String name, {required bool isRecommended}) {
  final Color baseColor = isRecommended ? AppColors.primaryGreen : Colors.grey;
  
  return InkWell(
    onTap: () {
       _vm.addIngredient(name);},

    // }=> _vm.addIngredient(name)
    borderRadius: BorderRadius.circular(30),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: isRecommended ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: baseColor.withValues(alpha: isRecommended ? 0.2 : 0.1)
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 14, color: isRecommended ? baseColor : Colors.grey),
          const SizedBox(width: 4),
          Text(
            name, 
            style: TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.w600,
              color: isRecommended ? Colors.black87 : Colors.black54,
            )
          ),
        ],
      ),
    ),
  );
}
}