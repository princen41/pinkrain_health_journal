import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class FormFieldLabel extends StatelessWidget {
  final String text;
  final EdgeInsets? margin;

  const FormFieldLabel({
    super.key,
    required this.text,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTokens.textStyleMedium,
        ),
      ),
    );
  }
}
