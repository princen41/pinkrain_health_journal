 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/router.dart';
import 'core/services/hive_service.dart';
import 'core/services/disclaimer_service.dart';
import 'core/theme/app_theme.dart';
import 'core/util/helpers.dart';
import 'features/journal/data/journal_log.dart';
import 'features/treatment/services/daily_reset_service.dart';
import 'features/treatment/services/medication_notification_service.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Show iOS status bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await HiveService.init();
  await DisclaimerService.init();
  
  // Initialize notification service at app startup with error handling
  try {
    final notificationService = MedicationNotificationService();
    await notificationService.initialize();
    
    // CRITICAL FIX: Schedule notifications for today's medications on app startup
    // This ensures that if the app was killed or restarted, notifications are rescheduled
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    devPrint('🚀 App startup: Scheduling notifications for today\'s medications');
    devPrint('   Current time: ${now.toString()}');
    
    final journalLog = JournalLog();
    final todayMeds = await journalLog.getMedicationsForTheDay(today);
    
    devPrint('   Loaded ${todayMeds.length} medications for today');
    
    // Only schedule notifications for medications that haven't been taken
    final untakenMeds = todayMeds.where((med) => !med.isTaken && !med.isSkipped).toList();
    devPrint('   Found ${untakenMeds.length} untaken/unskipped medications');
    
    await notificationService.showUntakenMedicationNotifications(untakenMeds);
    devPrint('✅ App startup: Scheduled notifications for ${untakenMeds.length} medications');
  } catch (e, stackTrace) {
    debugPrint('❌ Notification service initialization failed: $e\n$stackTrace');
    // Continue app startup even if notifications fail
  }
  
  // Initialize daily reset service
  final dailyResetService = DailyResetService();
  dailyResetService.initialize();

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
    );
  }
}