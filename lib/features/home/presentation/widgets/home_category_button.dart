import 'package:flutter/material.dart';
import '../../domain/enums/search_type.dart';
import '../../../../core/theme/app_colors.dart';

class HomeCategoryButton extends StatelessWidget {
  final SearchType type;
  final String label;
  final IconData icon;
  final Color baseColor;
  final bool isSelected;
  final VoidCallback onTap;

  const HomeCategoryButton({
    super.key,
    required this.type,
    required this.label,
    required this.icon,
    required this.baseColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          // withOpacity -> withValues 변경
          color: isSelected ? baseColor : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? baseColor : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: baseColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.white : AppColors.textGrey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}