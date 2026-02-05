import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:oman_fe/features/home/domain/enums/search_type.dart';
import '../widgets/animations/bounce_wrapper.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_category_button.dart';
import '../widgets/recipe_report_sheet.dart';
import '../widgets/yotube_recommendation_layer.dart';
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
  bool _isYoutubeLayerActive = false;
  bool _isButtonSlidingDown = false; // 버튼이 아래로 내려가는 중인가?
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _vm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _handleFloatingButtonTap() async {
    // 1. 눌림 액션 (작아짐)
    setState(() => _isButtonPressed = true);
    await Future.delayed(const Duration(milliseconds: 100)); // 0.1초

    // 2. 복구 액션 (원래 크기)
    setState(() => _isButtonPressed = false);
    await Future.delayed(const Duration(milliseconds: 100)); // 0.1초

    // 3. 아래로 슬라이드 다운
    setState(() => _isButtonSlidingDown = true);
    await Future.delayed(const Duration(milliseconds: 500)); // 0.5초 (슬라이드 시간)

    // 4. 유튜브 레이어 활성화
    if (mounted) {
      setState(() {
        _isYoutubeLayerActive = true;
        _isButtonSlidingDown = false; // 초기화
      });
    }
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
                  _vm.glowColor,
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _vm.setResultVisible(false),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                _buildMainUI(screenHeight),
              ],
            ),
          ),
          _buildResultLayer(sheetHeight),
          if (_isYoutubeLayerActive)
            YoutubeRecommendationLayer(
              onClose: () {
                // 레이어 내부에서 삭제 애니메이션이 끝나면 호출됨
                setState(() => _isYoutubeLayerActive = false);
              },
            ),
          if (!_isYoutubeLayerActive) // 유튜브 레이어가 활성화되면 버튼 숨김
            _buildFloatingButtonLayer(),
        ],
      ),
    );
  }

  Widget _buildMainUI(double screenHeight) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
      top: _vm.isResultVisible ? 40 : screenHeight * 0.22,
      left: 24,
      right: 24,
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
                key: _leftKey,
                isLeft: true,
                child: HomeCategoryButton(
                  type: SearchType.ingredients,
                  label: "재료",
                  icon: Icons.eco_rounded,
                  baseColor: AppColors.primaryGreen,
                  isSelected: _vm.selectedType == SearchType.ingredients,
                  onTap: () => _vm.toggleType(SearchType.ingredients),
                ),
              ),
              const SizedBox(width: 12),
              SequentialBounceWrapper(
                key: _rightKey,
                isLeft: false,
                child: HomeCategoryButton(
                  type: SearchType.recipe,
                  label: "요리",
                  icon: Icons.soup_kitchen_rounded,
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
      left: 0,
      right: 0,
      height: sheetHeight,
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
              isIngredientSearch: _vm.selectedType == SearchType.ingredients,
              selectedDishName: _vm.selectedDishName,
              onDishSelected: (dishName) => _vm.toggleDishSelection(dishName),
              onSelectionChanged: (hasSelection) => _vm.updateSelection(hasSelection),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtonLayer() {
    // 버튼이 보이는 조건: 뷰모델 visible AND 슬라이드 다운 전
    bool showPosition = _vm.finalButtonVisible && !_isButtonSlidingDown;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: showPosition ? Curves.easeOutBack : Curves.easeInOut,
      // 클릭 시퀀스가 끝나고 _isButtonSlidingDown이 true가 되면 -100으로 내려감
      bottom: showPosition ? 30 : -100, 
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 100),
          scale: _isButtonPressed ? 0.9 : 1.0, // 눌리면 0.9배, 아니면 1.0배
          curve: Curves.easeInOut,
          child: _buildFloatingButtonContent(),
        ),
      ),
    );
  }

  Widget _buildFloatingButtonContent() {
    const Color youtubeRed = Color(0xFFFF0000);
    return GestureDetector(
    onTap: _vm.finalButtonVisible ? _handleFloatingButtonTap : null,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: youtubeRed, // ✨ 빨간색 적용
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          if (_vm.finalButtonVisible)
            BoxShadow(
              color: youtubeRed.withValues(alpha: 0.4), // 그림자도 붉은색
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✨ 유튜브 느낌의 재생 아이콘
          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            "요리와 재료로 영상 찾기", // ✨ 텍스트 변경
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    ),
    );
  }

  // 📍 [수정] 요리 모드 대응 및 최근 요리 검색 섹션 추가
  Widget _buildSearchSuggestions() {
    final bool isIngredientMode = _vm.selectedType == SearchType.ingredients;
    final bool isRecipeMode = _vm.selectedType == SearchType.recipe;
    final bool hasType = _vm.selectedType != SearchType.none;
    final bool hasRecommendations = isIngredientMode && 
        _vm.searchController.text.isNotEmpty && 
        _vm.filteredCandidates.isNotEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      child: hasType
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
                  // 1. 추천 재료 (재료 모드에서만 노출)
                  if (isIngredientMode && hasRecommendations) ...[
                    const Text(
                      "추천 재료",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _vm.filteredCandidates
                          .map((name) => _buildSuggestionChip(name, 
                              isRecommended: true, 
                              overrideColor: isIngredientMode 
                                ? AppColors.primaryGreen 
                                : AppColors.primaryOrange
                              ))
                          .toList(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(
                          height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                  ],

                  // 2. 최근 검색어 (모드에 따라 타이틀 및 리스트 변경)
                  Text(
                    isIngredientMode ? "최근 검색한 재료" : "최근 검색한 요리",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Builder(builder: (context) {
                    final recentList = isIngredientMode 
                        ? _vm.recentSearches 
                        : _vm.recentRecipeSearches;

                    return recentList.isEmpty
                        ? const Text("최근 검색 기록이 없습니다.",
                            style: TextStyle(color: Colors.grey, fontSize: 13))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recentList
                                .map((name) => _buildSuggestionChip(name, 
                                    isRecommended: isIngredientMode,
                                    overrideColor: isIngredientMode 
                                        ? AppColors.primaryGreen 
                                        : AppColors.primaryOrange))
                                .toList(),
                          );
                  }),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // 📍 [수정] 칩 클릭 시 모드별 동작 분기 및 색상 처리
  Widget _buildSuggestionChip(String name, {required bool isRecommended, Color? overrideColor}) {
    final Color baseColor = overrideColor ?? (isRecommended ? AppColors.primaryGreen : Colors.grey);
    final double bgAlpha = isRecommended ? 0.12 : 0.05;
    final double borderAlpha = isRecommended ? 0.3 : 0.1;
    return InkWell(
      onTap: () {
        if (_vm.selectedType == SearchType.ingredients) {
          // 재료 모드: 태그로 추가
          _vm.addIngredient(name);
        } else if (_vm.selectedType == SearchType.recipe) {
          // 요리 모드: 검색창 텍스트 입력 후 즉시 검색 실행
          _vm.searchController.text = name;
          _vm.submitSearch(name);
        }
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: baseColor.withValues(alpha: borderAlpha)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add,
                size: 14, color: isRecommended ? baseColor : Colors.grey),
            const SizedBox(width: 4),
            Text(name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isRecommended ? Colors.black87 : Colors.black54,
                )),
          ],
        ),
      ),
    );
  }
}