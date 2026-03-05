import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/recipe_mock_data.dart';
import '../../domain/models/ingredient_search_result.dart';
import '../../domain/models/recipe_models.dart';

class RecipeReportSheet extends StatefulWidget {
  final bool isLoading;
  final bool isResultVisible;
  final bool isIngredientSearch;
  final Function(String) onDishSelected;
  final Function(bool) onSelectionChanged;
  final String? selectedDishName;
  final CulinaryIngredientGroupResponse? recipeDetailData;     // ✨ 추가
  final List<CulinaryRecommendationDto> ingredientResults;

  const RecipeReportSheet({
    super.key,
    required this.isLoading,
    required this.isResultVisible,
    this.isIngredientSearch = false,
    required this.onDishSelected,
    required this.onSelectionChanged,
    this.selectedDishName,
    this.recipeDetailData,
    this.ingredientResults = const [],
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
                    : widget.isIngredientSearch 
                        ? _buildIngredientSearchResultList(widget.ingredientResults) // ✨ 실제 데이터 전달
                        : _buildMainContent(widget.recipeDetailData),             // 상세 뷰 (요리 검색 결과)
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientSearchResultList(List<CulinaryRecommendationDto> results) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildRecipeCard(results[index]),
    );
  }

  // 개별 요리 결과 카드
Widget _buildRecipeCard(CulinaryRecommendationDto result) {
    String statusText = "";
    Color statusColor = Colors.grey;
    
    // 이전 더미의 result.dishName 대신 실제 DTO의 result.name 사용
    final bool isCardSelected = widget.selectedDishName == result.name;

    // 백엔드 Enum 상태 문자열에 맞게 조건 분기 (필요시 백엔드 값에 맞춰 대문자 수정)
    final String statusStr = result.status.toUpperCase();
    if (statusStr.contains("MATCH") || statusStr.contains("PERFECT")) {
      statusText = "완벽한 조합";
      statusColor = AppColors.primaryGreen;
    } else if (statusStr.contains("INSUFFICIENT") || statusStr.contains("LACK")) {
      statusText = "재료가 조금 더 필요해요";
      statusColor = Colors.redAccent;
    } else {
      statusText = "이 재료가 남아요";
      statusColor = AppColors.textGrey;
    }

    return GestureDetector(
      onTap: () => widget.onDishSelected(result.name), // dishName -> name
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCardSelected 
              ? AppColors.primaryGreen.withValues(alpha: 0.08) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCardSelected ? AppColors.primaryGreen : const Color(0xFFE2E8F0),
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
                  result.name, // dishName -> name
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    fontFamily: 'Pretendard',
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
            
            // 이전 더미의 result.targetIngredients 대신 실제 DTO의 result.ingredients 사용
            if (result.ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.ingredients.map((ing) {
                  // ✨ 실제 DTO는 객체이므로 ing.name으로 접근해야 합니다.
                  final bool isChipSelected = _selectedIngredients.contains(ing.name);
                  
                  // 상태별 컬러 로직 적용
                  Color bgColor;
                  Color textColor;
                  Color borderColor;
                  
                  Color insufficientDefault = Colors.redAccent.withValues(alpha: 0.1);
                  Color insufficientDefaultText = Colors.redAccent;
                  Color surplusDefault = AppColors.primaryGreen.withValues(alpha: 0.1);
                  Color surplusDefaultText = AppColors.primaryGreen;

                  if (statusStr.contains("INSUFFICIENT") || statusStr.contains("LACK")) {
                    bgColor = isChipSelected ? AppColors.primaryGreen : insufficientDefault;
                    textColor = isChipSelected ? Colors.white : insufficientDefaultText;
                    borderColor = isChipSelected ? AppColors.primaryGreen : Colors.redAccent.withValues(alpha: 0.2);
                  } else if (statusStr.contains("SURPLUS")) {
                    bgColor = isChipSelected ? insufficientDefault : surplusDefault;
                    textColor = isChipSelected ? insufficientDefaultText : surplusDefaultText;
                    borderColor = isChipSelected ? Colors.redAccent.withValues(alpha: 0.2) : AppColors.primaryGreen.withValues(alpha: 0.2);
                  } else {
                    bgColor = const Color(0xFFF1F5F9);
                    textColor = AppColors.textGrey;
                    borderColor = Colors.transparent;
                  }

                  return GestureDetector(
                    onTap: () => _toggleIngredient(ing.name), // ing -> ing.name
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        ing.name, // ing -> ing.name
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: (isChipSelected || statusStr.contains("SURPLUS") || statusStr.contains("INSUFFICIENT"))
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
  Widget _buildMainContent(CulinaryIngredientGroupResponse? data) {
    if (data == null) return const Center(child: Text("데이터를 불러오지 못했습니다."));

    // DTO 리스트에서 문자열 이름만 추출
    final essential = data.mainIngredients.map((e) => e.ingredientName).toList();
    final sub = data.subIngredients.map((e) => e.ingredientName).toList();
    final seasonings = data.otherIngredients.map((e) => e.ingredientName).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.selectedDishName ?? "", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          if (essential.isNotEmpty) ...[
            _buildBlock("핵심 재료", essential, _isEssentialOpen, () => setState(() => _isEssentialOpen = !_isEssentialOpen)),
            const SizedBox(height: 12),
          ],
          
          if (sub.isNotEmpty) ...[
            _buildBlock("부 재료", sub, _isSubOpen, () => setState(() => _isSubOpen = !_isSubOpen)),
            const SizedBox(height: 12),
          ],
          
          if (seasonings.isNotEmpty) ...[
            _buildBlock("선택 재료", seasonings, _isSeasoningOpen, () => setState(() => _isSeasoningOpen = !_isSeasoningOpen)),
          ],
          
          const SizedBox(height: 140),
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