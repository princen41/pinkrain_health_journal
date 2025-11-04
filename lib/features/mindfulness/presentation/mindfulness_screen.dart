import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pinkrain/core/theme/tokens.dart';

import '../../../core/widgets/appbar.dart';
import '../../../core/widgets/bottom_navigation.dart';

class MindfulnessScreen extends StatelessWidget {
  const MindfulnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bgPrimary,
      appBar: buildAppBar('Mindfulness'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a mindfulness practice',
                style: AppTokens.textStyleXLarge.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 24),
              _buildMindfulnessOption(
                context,
                title: 'Breathing Exercises',
                description: 'Calm your mind with guided breathing techniques',
                icon: HugeIcons.strokeRoundedFastWind,
                route: '/breath',
              ),
              const SizedBox(height: 16),
              _buildMindfulnessOption(
                context,
                title: 'Guided Meditation',
                description: 'Relax with soothing audio meditations',
                icon: HugeIcons.strokeRoundedYoga02,
                route: '/meditation',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(
        context: context,
        currentRoute: 'mindfulness',
      ),
    );
  }

  Widget _buildMindfulnessOption(
    BuildContext context, {
    required String title,
    required String description,
    required dynamic icon,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        context.go(route);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTokens.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTokens.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: AppTokens.iconPrimary,
              size: 28,
              strokeWidth: 1,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTokens.textStyleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTokens.textStyleSmall.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppTokens.iconMuted,
              size: 24,
              strokeWidth: 1,
            ),
          ],
        ),
      ),
    );
  }
}
