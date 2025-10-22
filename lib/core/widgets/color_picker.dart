import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class ColorPicker extends StatelessWidget {
  final String selectedColor;
  final String? selectedSecondaryColor;
  final ValueChanged<String> onChanged;
  final ValueChanged<String?>? onSecondaryChanged;
  final bool isDuotone;
  final double itemSize;

  // Centralized color map - single source of truth
  static const Map<String, Color> colorMap = {
    'White': Colors.white,
    'Yellow': Color(0xFFFFF1AD), // AppColors.pastelYellow
    'Pink': Color(0xFFFFD1FF),   // AppColors.pink100
    'Blue': Color(0xFFDBEFFF),   // AppColors.pastelBlue
    'Red': Color(0xFFFFC8C1),    // AppColors.pastelRed
    'Green': Color(0xFF8BE8CB),  // Default SVG green
  };

  const ColorPicker({
    super.key,
    required this.selectedColor,
    this.selectedSecondaryColor,
    required this.onChanged,
    this.onSecondaryChanged,
    this.isDuotone = false,
    this.itemSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Color label
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTokens.textPrimary,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Color selection - simple toggle behavior
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: colorMap.entries.map((entry) {
              final String colorName = entry.key;
              final Color color = entry.value;
              final bool isPrimarySelected = selectedColor == colorName;
              final bool isSecondarySelected = isDuotone && selectedSecondaryColor == colorName;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    if (isDuotone && onSecondaryChanged != null) {
                      // In duotone mode, allow selecting any two colors
                      if (isPrimarySelected) {
                        // If this is the primary color, deselect it
                        onChanged('White'); // Set to default
                      } else if (isSecondarySelected) {
                        // If this is the secondary color, deselect it
                        onSecondaryChanged!(null);
                      } else {
                        // If neither selected, check if we need primary or secondary
                        if (selectedColor == 'White') {
                          // No primary color selected yet, make this primary
                          onChanged(colorName);
                        } else if (selectedSecondaryColor == null) {
                          // Primary color selected, make this secondary
                          onSecondaryChanged!(colorName);
                        } else {
                          // Both colors selected, replace primary with this color
                          onChanged(colorName);
                        }
                      }
                    } else {
                      // Normal mode, toggle selection
                      if (isPrimarySelected) {
                        onChanged('White'); // Deselect by setting to default
                      } else {
                        onChanged(colorName);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: (isPrimarySelected || isSecondarySelected)
                            ? AppTokens.borderStrong
                            : AppTokens.borderLight,
                        width: (isPrimarySelected || isSecondarySelected) ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        colorName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                          color: (isPrimarySelected || isSecondarySelected) ? AppTokens.textPrimary : AppTokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
