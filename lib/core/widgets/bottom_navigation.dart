import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/tokens.dart';



dynamic _getIconForRoute(String route) {
  switch (route) {
    case 'journal':
      return HugeIcons.strokeRoundedBookOpen02;
    case 'pillbox':
      return HugeIcons.strokeRoundedTokenSquare;
    case 'mindfulness':
      return HugeIcons.strokeRoundedFlower;
    case 'wellness':
      return HugeIcons.strokeRoundedYoga03;
    default:
      return HugeIcons.strokeRoundedBookmark02;
  }
}

Widget buildBottomNavigationBar({required BuildContext context, required String currentRoute}) {
  return BottomAppBar(
    color: Colors.transparent,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildNavItem(context, 'Journal', 'journal', currentRoute == 'journal'),
        buildNavItem(context, 'Pillbox', 'pillbox', currentRoute == 'pillbox'),
        buildNavItem(context, 'Mindfulness', 'mindfulness',
            currentRoute == 'mindfulness' || currentRoute == 'breath' || currentRoute == 'meditation'),
        buildNavItem(context, 'Wellness', 'wellness', currentRoute == 'wellness'),
      ],
    ),
  );
}

GestureDetector buildNavItem(BuildContext context, String label, String route, bool isSelected) {
  return GestureDetector(
    onTap: () {
      if (!isSelected) {
        context.go('/$route');
      }
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppTokens.bgCard : Colors.transparent,
        ),
        padding: EdgeInsets.all(8),
        child: HugeIcon(
          icon: _getIconForRoute(route),
          size: 21,
          strokeWidth: 1,
          color: isSelected ? AppTokens.textPrimary : AppTokens.textSecondary,
        )
        ),

        Text(label),
      ],
    ),
  );
}