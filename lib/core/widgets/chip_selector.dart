import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class ChipSelector extends StatelessWidget {
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final double height;
  final Widget Function(String option, bool isSelected)? itemBuilder;

  const ChipSelector({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.height = 100,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: options.map((option) {
          final bool isSelected = selectedValue == option;
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: itemBuilder?.call(option, isSelected) ?? 
                _defaultItemBuilder(option, isSelected),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _defaultItemBuilder(String option, bool isSelected) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? AppTokens.bgCard : Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? AppTokens.iconBold : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              option.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTokens.textPrimary : AppTokens.textSecondary,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          option,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTokens.textPrimary : AppTokens.textSecondary,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }
}
