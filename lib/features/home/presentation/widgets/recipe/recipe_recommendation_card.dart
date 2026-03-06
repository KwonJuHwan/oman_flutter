import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/recipe_models.dart';

class RecipeRecommendationCard extends StatelessWidget {
  final CulinaryRecommendationDto result;
  final String? selectedDishName;
  final Set<String> selectedIngredients;
  final ValueChanged<String> onDishSelected;
  final ValueChanged<String> onToggleIngredient;

  const RecipeRecommendationCard({
    super.key,
    required this.result,
    required this.selectedDishName,
    required this.selectedIngredients,
    required this.onDishSelected,
    required this.onToggleIngredient,
  });

  @override
  Widget build(BuildContext context) {
    String statusText = "";
    Color statusColor = Colors.grey;
    final bool isCardSelected = selectedDishName == result.name;
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
      onTap: () => onDishSelected(result.name),
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
                  result.name,
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
            if (result.ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.ingredients.map((ing) {
                  final bool isChipSelected = selectedIngredients.contains(ing.name);
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
                    onTap: () => onToggleIngredient(ing.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        ing.name,
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
}