import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class IntakeRuleSelector extends StatelessWidget {
  final String selectedRule;
  final ValueChanged<String> onSelect;

  const IntakeRuleSelector({
    super.key,
    required this.selectedRule,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final rules = [
      ('before_meal', 'Before Meal'),
      ('after_meal', 'After Meal'),
      ('with_meal', 'With Meal'),
      ('empty_stomach', 'Empty Stomach'),
      ('anytime', 'Anytime'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rules
          .map(
            (rule) => GestureDetector(
              onTap: () => onSelect(rule.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selectedRule == rule.$1
                      ? AppColors.primary
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rule.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selectedRule == rule.$1
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
