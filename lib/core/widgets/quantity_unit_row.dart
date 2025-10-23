import 'package:flutter/material.dart';
import 'custom_text_field.dart';
import 'unit_dropdown.dart';

class QuantityUnitRow extends StatelessWidget {
  final TextEditingController quantityController;
  final String selectedUnit;
  final ValueChanged<String?> onUnitChanged;
  final String? quantityError;
  final VoidCallback? onQuantityChanged;
  final List<String> units;

  const QuantityUnitRow({
    super.key,
    required this.quantityController,
    required this.selectedUnit,
    required this.onUnitChanged,
    this.quantityError,
    this.onQuantityChanged,
    this.units = const ['mg', 'g', 'ml', 'pills'],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CustomTextField(
            controller: quantityController,
            hintText: 'Quantity',
            isNumberField: true,
            errorText: quantityError,
            onChanged: onQuantityChanged,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: UnitDropdown(
            value: selectedUnit,
            onChanged: onUnitChanged,
            units: units,
          ),
        ),
      ],
    );
  }
}
