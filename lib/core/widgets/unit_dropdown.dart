import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class UnitDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final List<String> units;
  final double? height;

  const UnitDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.units = const ['mg', 'g', 'ml', 'pills'],
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 56,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: units.map((String unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(
                unit,
                style: const TextStyle(
                  color: AppTokens.textPrimary,
                  fontFamily: 'Outfit',
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
