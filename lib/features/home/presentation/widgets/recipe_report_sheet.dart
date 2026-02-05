import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/recipe_mock_data.dart';
import '../../domain/models/ingredient_search_result.dart';

class RecipeReportSheet extends StatefulWidget {
  final bool isLoading;
  final bool isResultVisible;
  final bool isIngredientSearch;
  final Function(String) onDishSelected;
  final Function(bool) onSelectionChanged;
  final String? selectedDishName;

  const RecipeReportSheet({
    super.key,
    required this.isLoading,
    required this.isResultVisible,
    this.isIngredientSearch = false,
    required this.onDishSelected,
    required this.onSelectionChanged,
    this.selectedDishName,
  });

  @override
  State<RecipeReportSheet> createState() => _RecipeReportSheetState();
}

class _RecipeReportSheetState extends State<RecipeReportSheet> {
  bool _isEssentialOpen = true;
  bool _isSubOpen = false;
  bool _isSeasoningOpen = false;
  final Set<String> _selectedIngredients = {};

void _toggleIngredient(String name) {
    setState(() {
      _selectedIngredients.contains(name)
          ? _selectedIngredients.remove(name)
          : _selectedIngredients.add(name);
    });

    widget.onSelectionChanged(_selectedIngredients.isNotEmpty);
  }
  @override
  void didUpdateWidget(RecipeReportSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 검색 결과가 새로 나타나는 시점에 선택된 칩들을 초기화
    if (widget.isResultVisible && !oldWidget.isResultVisible) {
      setState(() {
        _selectedIngredients.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeDetailData = RecipeMockData.kimchiStew;
    final ingredientResults = [
    IngredientSearchResult(
      dishName: "김치찌개", 
      status: IngredientMatchStatus.match, 
      targetIngredients: []
    ),
    IngredientSearchResult(
      dishName: "된장찌개", 
      status: IngredientMatchStatus.insufficient, 
      targetIngredients: ["두부", "팽이버섯"]
    ),
    IngredientSearchResult(
      dishName: "부대찌개", 
      status: IngredientMatchStatus.surplus, 
      targetIngredients: ["스팸", "소시지"]
    ),
  ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // 상단 핸들 바
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
          child: widget.isLoading
              ? _buildLoadingSkeleton()
              : !widget.isResultVisible
                  ? const SizedBox.expand()
                  // ✨ 조건부 렌더링: 재료 검색 모드인지에 따라 위젯 분기
                  : widget.isIngredientSearch 
                      ? _buildIngredientSearchResultList(ingredientResults) // 리스트 뷰 (재료 검색 결과)
                      : _buildMainContent(recipeDetailData),               // 상세 뷰 (요리 검색 결과)
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientSearchResultList(List<IngredientSearchResult> results) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildRecipeCard(results[index]),
    );
  }

  // 개별 요리 결과 카드
  Widget _buildRecipeCard(IngredientSearchResult result) {
    String statusText = "";
    Color statusColor = Colors.grey;
    final bool isCardSelected = widget.selectedDishName == result.dishName;

    switch (result.status) {
      case IngredientMatchStatus.match:
        statusText = "완벽한 조합";
        statusColor = AppColors.primaryGreen;
        break;
      case IngredientMatchStatus.insufficient:
        statusText = "재료가 조금 더 필요해요";
        statusColor = Colors.redAccent; // 👈 상태 텍스트도 빨간색으로 변경
        break;
      case IngredientMatchStatus.surplus:
        statusText = "이 재료가 남아요";
        statusColor = AppColors.textGrey;
        break;
    }

    return GestureDetector(
      onTap: () => widget.onDishSelected(result.dishName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // ✨ 선택 시: 아주 옅은 초록색 배경
          color: isCardSelected 
              ? AppColors.primaryGreen.withValues(alpha: 0.08) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // ✨ 선택 시: 초록색 테두리
            color: isCardSelected 
                ? AppColors.primaryGreen 
                : const Color(0xFFE2E8F0),
            width: isCardSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  result.dishName,
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    fontFamily: 'Pretendard',
                    // 선택 시 텍스트 색상도 살짝 강조
                    color: isCardSelected ? AppColors.primaryGreen : Colors.black87,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ],
            ),
            
            if (result.targetIngredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              // 재료 칩 영역
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.targetIngredients.map((ing) {
                  // 칩 내부 상태 확인
                  final bool isChipSelected = _selectedIngredients.contains(ing);
                  final bool isInsufficientMode = result.status == IngredientMatchStatus.insufficient;
                  final bool isSurplusMode = result.status == IngredientMatchStatus.surplus;

                  // 색상 로직 (이전 요청사항 반영)
                  Color bgColor;
                  Color textColor;
                  Color borderColor;
                  
                  Color insufficientDefault = Colors.redAccent.withValues(alpha: 0.1);
                  Color insufficientDefaultText = Colors.redAccent;
                  Color surplusDefault = AppColors.primaryGreen.withValues(alpha: 0.1);
                  Color surplusDefaultText = AppColors.primaryGreen;

                  if (isInsufficientMode) {
                    // 부족해요: 기본(빨강) -> 클릭(초록)
                    bgColor = isChipSelected ? AppColors.primaryGreen : insufficientDefault;
                    textColor = isChipSelected ? Colors.white : insufficientDefaultText;
                    borderColor = isChipSelected ? AppColors.primaryGreen : Colors.redAccent.withValues(alpha: 0.2);
                  } else if (isSurplusMode) {
                    // 남아요: 기본(초록) -> 클릭(빨강)
                    bgColor = isChipSelected ? insufficientDefault : surplusDefault;
                    textColor = isChipSelected ? insufficientDefaultText : surplusDefaultText;
                    borderColor = isChipSelected ? Colors.redAccent.withValues(alpha: 0.2) : AppColors.primaryGreen.withValues(alpha: 0.2);
                  } else {
                    bgColor = const Color(0xFFF1F5F9);
                    textColor = AppColors.textGrey;
                    borderColor = Colors.transparent;
                  }

                  // ✨ [자식 제스처] 칩 클릭 시 -> 재료 토글만 수행 (부모 이벤트 차단됨)
                  return GestureDetector(
                    onTap: () => _toggleIngredient(ing),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        ing,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: (isChipSelected || isSurplusMode || isInsufficientMode)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 실제 검색 결과 내용
  Widget _buildMainContent(dynamic data) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), // 부드러운 스크롤감
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.dishName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 32),
          
          _buildBlock("핵심 재료", data.essential, _isEssentialOpen,
              () => setState(() => _isEssentialOpen = !_isEssentialOpen)),
          const SizedBox(height: 12),
          
          _buildBlock("부 재료", data.subIngredients, _isSubOpen,
              () => setState(() => _isSubOpen = !_isSubOpen)),
          const SizedBox(height: 12),
          
          _buildBlock("선택 재료", data.seasonings, _isSeasoningOpen,
              () => setState(() => _isSeasoningOpen = !_isSeasoningOpen)),
          
          const SizedBox(height: 140), // 하단 버튼 여백 확보
        ],
      ),
    );
  }

  // 아코디언 블록 위젯
  Widget _buildBlock(String title, List<String> items, bool isOpen, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Pretendard')),
            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: isOpen ? 0.5 : 0, // 아이콘 회전 효과
              child: const Icon(Icons.keyboard_arrow_down),
            ),
            onTap: onTap,
          ),
          
          // 📍 부드러운 열고 닫기 액션 (AnimatedCrossFade)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 5),
              // 📍 GridView 대신 Wrap을 사용하여 잘림 방지 및 자동 줄바꿈
              child: Wrap(
                spacing: 8.0, // 가로 간격
                runSpacing: 8.0, // 세로 간격
                children: items.map((item) => _buildItem(item)).toList(),
              ),
            ),
            crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // 재료 개별 아이템 위젯
  Widget _buildItem(String name) {
    bool isSelected = _selectedIngredients.contains(name);
    return GestureDetector(
      onTap: () => _toggleIngredient(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.withValues(alpha: 0.1),
      highlightColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}