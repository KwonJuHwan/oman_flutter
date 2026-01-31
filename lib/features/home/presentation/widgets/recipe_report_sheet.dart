import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/recipe_mock_data.dart';

class RecipeReportSheet extends StatefulWidget {
  final bool isLoading;
  final bool isResultVisible;
  final Function(bool) onSelectionChanged;

  const RecipeReportSheet({
    super.key,
    required this.isLoading,
    required this.isResultVisible,
    required this.onSelectionChanged,
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
  Widget build(BuildContext context) {
    final data = RecipeMockData.kimchiStew;

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
                    : _buildMainContent(data),
          ),
        ],
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