import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pinkrain/core/theme/colors.dart';
import 'package:pinkrain/core/theme/icons.dart';
import 'package:pinkrain/core/theme/tokens.dart';

class BreathingExerciseSelector extends StatelessWidget {
  final String selectedExercise;
  final int selectedCycles;
  final ValueChanged<String> onExerciseSelected;
  final ValueChanged<int> onCyclesChanged;

  const BreathingExerciseSelector({
    super.key,
    required this.selectedExercise,
    required this.selectedCycles,
    required this.onExerciseSelected,
    required this.onCyclesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a breathing exercise',
          style: AppTokens.textStyleLarge,
        ),
        const SizedBox(height: 20),
        _buildExerciseOption(
          'Box Breathing',
          'Inhale, hold, exhale, and hold, each for 4 seconds',
          'box',
          'box',
        ),
        _buildExerciseOption(
          '4-7-8 Breathing',
          'Inhale for 4, hold for 7, exhale for 8 seconds',
          '4-7-8',
          'bow',
        ),
        _buildExerciseOption(
          'Calming Breath',
          'Simple inhale and exhale for 5 seconds each',
          'calm',
          'boat',
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Number of cycles:',
              style: AppTokens.textStyleMedium,
            ),
            GestureDetector(
              onTap: () async {
                final cycles = [3, 4, 5, 6, 7, 8, 9, 10];
                final currentIndex = cycles.indexOf(selectedCycles);
                final initialIndex = currentIndex >= 0 ? currentIndex : 0;
                
                await showCupertinoModalPopup(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                      height: 200,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                      child: SafeArea(
                        top: false,
                        child: CupertinoPicker(
                          itemExtent: 50,
                          scrollController: FixedExtentScrollController(
                            initialItem: initialIndex,
                          ),
                          onSelectedItemChanged: (int index) {
                            onCyclesChanged(cycles[index]);
                          },
                          children: cycles.map((int cycle) {
                            return Center(
                              child: Text(
                                '$cycle',
                                style: AppTokens.textStyleLarge,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                );
                // Ensure keyboard doesn't appear after picker closes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusScope.of(context).unfocus();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTokens.bgMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTokens.borderLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$selectedCycles',
                      style: AppTokens.textStyleMedium,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppTokens.iconPrimary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseOption(
    String title,
    String description,
    String type,
    String iconFileName,
  ) {
    final isSelected = selectedExercise == type;

    return GestureDetector(
      onTap: () => onExerciseSelected(type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.bgCard : AppTokens.bgPrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTokens.borderLight : AppTokens.borderLight,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.pink40.withAlpha(30),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.pink100 : AppTokens.bgMuted,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: appVectorImage(
                  fileName: iconFileName,
                  size: 24,
                  color: isSelected ? AppTokens.iconPrimary : AppTokens.iconMuted,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: AppTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

