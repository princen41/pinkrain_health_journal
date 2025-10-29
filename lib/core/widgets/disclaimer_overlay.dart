import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/disclaimer_service.dart';
import '../theme/colors.dart';
import '../theme/tokens.dart';
import 'buttons.dart';

class DisclaimerOverlay extends StatelessWidget {
  final VoidCallback onAccepted;
  
  const DisclaimerOverlay({
    super.key,
    required this.onAccepted,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black80.withValues(alpha: 0.7),
      child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: double.infinity,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTokens.bgPrimary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black40,
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppTokens.stateError,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Important Disclaimer',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTokens.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Main disclaimer text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTokens.stateError.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IMPORTANT DISCLAIMER:',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTokens.stateError,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This app is NOT a medical device and does not claim to improve your mental or physical health in any way. It should NEVER be considered a replacement for professional healthcare providers, licensed therapists, psychiatrists, or medical professionals.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.black100,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Additional warnings
                  Text(
                    'Please note:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildBulletPoint('Always consult with qualified healthcare providers for medical advice, diagnosis, or treatment'),
                  _buildBulletPoint('This app is for informational and wellness tracking purposes only'),
                  _buildBulletPoint('Do not use this app for medical emergencies - contact emergency services immediately'),
                  _buildBulletPoint('Do not stop or modify prescribed medications without consulting your healthcare provider'),
                  _buildBulletPoint('If you are experiencing a mental health crisis, contact a mental health professional or crisis hotline'),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Button.primary(
                          onPressed: () => _onAccept(context),
                          text: 'I Understand & Agree',
                          fontSize: 16,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          size: ButtonSize.large,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Button.secondary(
                          onPressed: () => _onDecline(context),
                          text: 'I Do Not Agree',
                          fontSize: 16,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textColor: AppTokens.stateError,
                          size: ButtonSize.large,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Footer note
                  Text(
                    'By continuing to use this app, you acknowledge that you have read, understood, and agree to this disclaimer.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.black60,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 12),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.black80,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                height: 1.4,
                color: AppColors.black80,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAccept(BuildContext context) async {
    await DisclaimerService.acceptDisclaimer();
    onAccepted();
  }

  void _onDecline(BuildContext context) {
    // Show confirmation dialog before closing the app
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppTokens.bgPrimary,
          title: Text(
            'Exit App',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              color: AppTokens.textPrimary,
            ),
          ),
          content: Text(
            'You must accept the disclaimer to use this app. What would you like to do?',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.black80,
            ),
          ),
          actions: [
            Button.secondary(
              onPressed: () => Navigator.of(context).pop(),
              text: 'Review Again',
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(width: 8),
              Button.secondary(
                onPressed: () {
                  // Close the app (Android only)
                  SystemNavigator.pop();
                },
                text: 'Exit App',
                fontSize: 14,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textColor: AppTokens.stateError,
              ),
            ],
          ],
        );
      },
    );
  }
}