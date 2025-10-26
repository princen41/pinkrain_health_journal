import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

enum ButtonSize {
  small,
  medium,
  large,
}

class Button {
  static TextButton primary({
    required VoidCallback onPressed,
    required String text,
    ButtonSize size = ButtonSize.medium,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    String fontFamily = 'Outfit',
    EdgeInsets? padding,
    double borderRadius = 12,
    Color textColor = AppTokens.textPrimary,
    Color backgroundColor = AppColors.pink100,
    Color borderColor = AppTokens.borderLight,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    final buttonPadding = padding ?? _getPaddingForSize(size);
    final buttonFontSize = _getFontSizeForSize(size, fontSize);
    return _baseButton(
      onPressed: onPressed,
      text: text,
      textColor: textColor,
      backgroundColor: backgroundColor,
      borderColor: Colors.transparent,
      borderWidth: 0,
      fontSize: buttonFontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      padding: buttonPadding,
      borderRadius: borderRadius,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  static TextButton secondary({
    required VoidCallback onPressed,
    required String text,
    ButtonSize size = ButtonSize.medium,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    String fontFamily = 'Outfit',
    EdgeInsets? padding,
    double borderRadius = 12,
    Color textColor = AppTokens.textPrimary,
    Color backgroundColor = AppTokens.buttonSecondaryBg,
    Color borderColor = AppTokens.borderLight,
    double borderWidth = 1.5,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    final buttonPadding = padding ?? _getPaddingForSize(size);
    final buttonFontSize = _getFontSizeForSize(size, fontSize);
    return _baseButton(
      onPressed: onPressed,
      text: text,
      textColor: textColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      fontSize: buttonFontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      padding: buttonPadding,
      borderRadius: borderRadius,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  static TextButton destructive({
    required VoidCallback onPressed,
    required String text,
    ButtonSize size = ButtonSize.medium,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    String fontFamily = 'Outfit',
    EdgeInsets? padding,
    double borderRadius = 12,
    Color textColor = AppTokens.stateError,
    Color backgroundColor = AppTokens.buttonSecondaryBg,
    Color borderColor = AppTokens.borderLight,
    double borderWidth = 0,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    final buttonPadding = padding ?? _getPaddingForSize(size);
    final buttonFontSize = _getFontSizeForSize(size, fontSize);
    return _baseButton(
      onPressed: onPressed,
      text: text,
      textColor: textColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      fontSize: buttonFontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      padding: buttonPadding,
      borderRadius: borderRadius,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  static TextButton _baseButton({
    required VoidCallback onPressed,
    required String text,
    required Color textColor,
    required Color backgroundColor,
    required Color borderColor,
    required double borderWidth,
    required double fontSize,
    required FontWeight fontWeight,
    required String fontFamily,
    required EdgeInsets padding,
    required double borderRadius,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    Widget child;
    
    if (leadingIcon != null || trailingIcon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            leadingIcon,
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontFamily: fontFamily,
              color: textColor,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            trailingIcon,
          ],
        ],
      );
    } else {
      child = Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          color: textColor,
        ),
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: padding,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        ),
      ),
      child: child,
    );
  }

  static EdgeInsets _getPaddingForSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  static double _getFontSizeForSize(ButtonSize size, double customFontSize) {
    if (customFontSize != 16) return customFontSize; // Use custom if provided
    
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }
}
