import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
      // Log warning about unknown route
      debugPrint('⚠️ Unknown route in bottom navigation: "$route". Using fallback bookmark icon.');
      
      // In debug/dev mode, throw to surface the routing issue
      if (kDebugMode) {
        throw AssertionError(
          'Unknown route "$route" passed to _getIconForRoute. '
          'This indicates a routing configuration issue. '
          'Valid routes are: journal, pillbox, mindfulness, wellness.'
        );
      }
      
      // Return safe fallback icon for release builds
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
      mainAxisAlignment: MainAxisAlignment.center,
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
          size: 19,
          strokeWidth: 1,
          color: isSelected ? AppTokens.textPrimary : AppTokens.textSecondary,
        )
        ),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    ),
  );
}