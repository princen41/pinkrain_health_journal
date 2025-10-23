import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? errorText;
  final VoidCallback? onChanged;
  final bool isNumberField;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.isNumberField = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: AppTokens.cursor,
      keyboardType: isNumberField 
          ? (Platform.isIOS 
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number)
          : keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTokens.textPlaceholder),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(15),
        errorText: errorText,
        errorStyle: const TextStyle(
          color: AppTokens.stateError,
          fontSize: 12,
        ),
      ),
      onChanged: onChanged != null ? (_) => onChanged!() : null,
    );
  }
}
