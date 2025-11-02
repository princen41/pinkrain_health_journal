import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class ColorPicker extends StatelessWidget {
  final String? selectedColor;
  final String? selectedSecondaryColor;
  final ValueChanged<String?> onChanged;
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

  ColorPicker({
    super.key,
    this.selectedColor,
    this.selectedSecondaryColor,
    required this.onChanged,
    this.onSecondaryChanged,
    this.isDuotone = false,
    this.itemSize = 40,
  }) : assert(
         selectedColor == null || colorMap.containsKey(selectedColor),
         'ColorPicker: selectedColor must be null or exist in colorMap (White, Yellow, Pink, Blue, Red, Green)',
       ),
       assert(
         !isDuotone || selectedSecondaryColor == null || colorMap.containsKey(selectedSecondaryColor),
         'ColorPicker: selectedSecondaryColor must exist in colorMap (White, Yellow, Pink, Blue, Red, Green)',
       );

  /// Helper method to determine contrasting text color based on background luminance
  /// Returns darker text for light backgrounds and lighter text for dark backgrounds
  Color _getContrastingTextColor(Color backgroundColor, bool isSelected) {
    final double luminance = backgroundColor.computeLuminance();
    
    // Threshold of 0.5 is a common choice for determining light vs dark backgrounds
    // Lighter backgrounds (luminance > 0.5) get dark text
    // Darker backgrounds (luminance <= 0.5) get light text
    if (luminance > 0.5) {
      // Light background - use dark text
      return isSelected ? AppTokens.textPrimary : AppTokens.textSecondary;
    } else {
      // Dark background - use light text
      return isSelected ? Colors.white : Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Runtime validation with safe fallback when assertions are disabled
    final String? validatedPrimaryColor = selectedColor == null || colorMap.containsKey(selectedColor)
        ? selectedColor
        : null;
    
    final String? validatedSecondaryColor = isDuotone && selectedSecondaryColor != null
        ? (colorMap.containsKey(selectedSecondaryColor!) ? selectedSecondaryColor : null)
        : selectedSecondaryColor;
    
    // Log warning if fallback was used (helps debugging in release mode)
    if (validatedPrimaryColor != selectedColor) {
      debugPrint(
        'ColorPicker: Invalid selectedColor "$selectedColor" was replaced with null. '
        'Valid colors are: ${colorMap.keys.join(", ")}'
      );
    }
    
    if (isDuotone && selectedSecondaryColor != null && validatedSecondaryColor != selectedSecondaryColor) {
      debugPrint(
        'ColorPicker: Invalid selectedSecondaryColor "$selectedSecondaryColor" was replaced with null. '
        'Valid colors are: ${colorMap.keys.join(", ")}'
      );
    }
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
          height: itemSize + 2, // itemSize + small buffer for borders
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: colorMap.entries.map((entry) {
              final String colorName = entry.key;
              final Color color = entry.value;
              final bool isPrimarySelected = validatedPrimaryColor == colorName;
              final bool isSecondarySelected = isDuotone && validatedSecondaryColor == colorName;

              return Padding(
                padding: EdgeInsets.only(right: itemSize * 0.3), // Scales proportionally (12 for default 40)
                child: GestureDetector(
                  onTap: () {
                    if (isDuotone && onSecondaryChanged != null) {
                      // Duotone mode: Allow selecting any two colors
                      // UX behavior:
                      // 1. Tapping a selected color deselects it
                      // 2. Tapping a new color when both slots are empty/default fills primary first
                      // 3. Tapping a new color when one slot is filled adds it as secondary
                      // 4. Tapping a new color when both are filled replaces the secondary
                      //    (most recently selected), which feels more intuitive than replacing primary
                      
                      if (isPrimarySelected) {
                        // Tap on primary color → deselect it by resetting to default
                        onChanged(null);
                      } else if (isSecondarySelected) {
                        // Tap on secondary color → deselect it
                        onSecondaryChanged!(null);
                      } else {
                        // Tapping a new (unselected) color
                        if (validatedPrimaryColor == null) {
                          // No primary color selected yet → set as primary
                          onChanged(colorName);
                        } else if (validatedSecondaryColor == null) {
                          // Primary exists but no secondary → set as secondary
                          onSecondaryChanged!(colorName);
                        } else {
                          // Both colors already selected → replace secondary (most recent)
                          // This is more intuitive as users typically want to adjust their
                          // last selection rather than the first one
                          onSecondaryChanged!(colorName);
                        }
                      }
                    } else {
                      // Normal mode, toggle selection
                      if (isPrimarySelected) {
                        onChanged(null); // Deselect by setting to null
                      } else {
                        onChanged(colorName);
                      }
                    }
                  },
                  child: Semantics(
                    label: '$colorName color${(isPrimarySelected || isSecondarySelected) ? ", selected" : ""}',
                    button: true,
                    selected: (isPrimarySelected || isSecondarySelected),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: itemSize * 0.4,  // Scales proportionally (16 for default 40)
                        vertical: itemSize * 0.1,     // Scales proportionally (4 for default 40)
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(itemSize * 0.75), // Scales proportionally (30 for default 40)
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
                            color: _getContrastingTextColor(color, isPrimarySelected || isSecondarySelected),
                          ),
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
