import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/enums/search_type.dart';
import '../../../domain/models/recipe_models.dart';
import '../../state/home_viewmodel.dart';

class SearchSuggestionsBox extends StatelessWidget {
  final HomeViewModel vm;

  const SearchSuggestionsBox({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder를 사용하여 내부 상태 변화만 감지
    return ListenableBuilder(
      listenable: vm,
      builder: (context, child) {
        final bool isIngredientMode = vm.selectedType == SearchType.ingredients;
        final bool hasType = vm.selectedType != SearchType.none;
        final bool hasRecommendations = isIngredientMode && 
            vm.searchController.text.isNotEmpty && 
            vm.filteredCandidates.isNotEmpty;

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
                      // 1. 추천 재료
                      if (isIngredientMode && hasRecommendations) ...[
                        const Text(
                          "추천 재료",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: vm.filteredCandidates
                              .map((dto) => _buildSuggestionChip(dto, isRecommended: true, overrideColor: AppColors.primaryGreen, isRecent: false))
                              .toList(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                      ],

                      // 2. 최근 검색어
                      Text(
                        isIngredientMode ? "최근 검색한 재료" : "최근 검색한 요리",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Builder(builder: (context) {
                        final recentList = isIngredientMode ? vm.recentIngredientSearches : vm.recentRecipeSearches;

                        return recentList.isEmpty
                            ? const Text("최근 검색 기록이 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 13))
                            : Wrap(
                                spacing: 8, runSpacing: 8,
                                children: recentList.map((item) {
                                  // 요리는 String이므로 파싱
                                  final IngredientSimpleDto dto = item is IngredientSimpleDto 
                                      ? item 
                                      : IngredientSimpleDto(id: 0, name: item.toString());
                                  return _buildSuggestionChip(dto, 
                                      isRecommended: false, 
                                      overrideColor: isIngredientMode ? AppColors.primaryGreen : AppColors.primaryOrange, 
                                      isRecent: true);
                                }).toList(),
                              );
                      }),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildSuggestionChip(IngredientSimpleDto item, {required bool isRecommended, Color? overrideColor, required bool isRecent}) {
    final Color baseColor = overrideColor ?? (isRecommended ? AppColors.primaryGreen : Colors.grey);
    final double bgAlpha = isRecommended ? 0.12 : 0.05;
    final double borderAlpha = isRecommended ? 0.3 : 0.1;
    final String name = item.name;

    return InkWell(
      onTap: () {
        if (vm.selectedType == SearchType.ingredients) {
          vm.addIngredient(item);
        } else if (vm.selectedType == SearchType.recipe) {
          vm.searchController.text = name;
          vm.submitSearch(name);
        }
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: baseColor.withValues(alpha: borderAlpha)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecommended) ...[
              Icon(Icons.add, size: 14, color: baseColor),
              const SizedBox(width: 4),
            ],
            Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isRecommended ? Colors.black87 : Colors.black54)),
            if (isRecent) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => vm.removeRecentSearch(item), 
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }
}