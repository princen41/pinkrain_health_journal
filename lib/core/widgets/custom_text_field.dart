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
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.isNumberField = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
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
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
                maxWidth: 48,
                maxHeight: 48,
              )
            : null,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIcon != null
            ? const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
                maxWidth: 48,
                maxHeight: 48,
              )
            : null,
        errorText: errorText,
        errorStyle: const TextStyle(
          color: AppTokens.stateError,
          fontSize: 12,
        ),
        labelStyle: const TextStyle(color: AppTokens.textPrimary),
      ),
      style: AppTokens.textStyleMedium,
      onChanged: onChanged != null ? (_) => onChanged!() : null,
    );
  }
}
