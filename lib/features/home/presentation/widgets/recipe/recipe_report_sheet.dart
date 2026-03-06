import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/recipe_models.dart';
import 'recipe_recommendation_card.dart'; // ✨ 신규 분리된 카드 임포트

class RecipeReportSheet extends StatefulWidget {
  final bool isLoading;
  final bool isResultVisible;
  final bool isIngredientSearch;
  final Function(String) onDishSelected;
  final Function(bool) onSelectionChanged;
  final String? selectedDishName;
  final CulinaryIngredientGroupResponse? recipeDetailData;     
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
                        ? _buildIngredientSearchResultList(widget.ingredientResults) 
                        : _buildMainContent(widget.recipeDetailData),            
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
      itemBuilder: (context, index) => RecipeRecommendationCard( // ✨ 추출한 위젯 사용
        result: results[index],
        selectedDishName: widget.selectedDishName,
        selectedIngredients: _selectedIngredients,
        onDishSelected: widget.onDishSelected,
        onToggleIngredient: _toggleIngredient,
      ),
    );
  }

  Widget _buildMainContent(CulinaryIngredientGroupResponse? data) {
    if (data == null) return const Center(child: Text("데이터를 불러오지 못했습니다."));

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
              turns: isOpen ? 0.5 : 0, 
              child: const Icon(Icons.keyboard_arrow_down),
            ),
            onTap: onTap,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 5),
              child: Wrap(
                spacing: 8.0, 
                runSpacing: 8.0, 
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