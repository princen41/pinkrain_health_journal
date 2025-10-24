import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
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
    return GestureDetector(
      onTap: () async {
        await showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 150,
              color: Colors.white,
              child: CupertinoPicker(
                itemExtent: 50,
                onSelectedItemChanged: (int index) {
                  onChanged(units[index]);
                },
                children: units.map((String unit) {
                  return Center(
                    child: Text(
                      unit,
                      style: AppTokens.textStyleLarge,
                    ),
                  );
                }).toList(),
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
        height: height ?? 56,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Text(
              value,
              style: AppTokens.textStyleMedium,
            ),
            const Spacer(),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              color: AppTokens.iconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
