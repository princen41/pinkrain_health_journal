import 'dart:async';

import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/data/journal_log.dart';
import 'package:pinkrain/features/treatment/services/medication_notification_service.dart';

/// Service to handle daily reset operations for the app
/// This follows clean architecture by separating the daily reset logic
/// from the notification service itself
class DailyResetService {
  static final DailyResetService _instance = DailyResetService._internal();
  
  factory DailyResetService() {
    return _instance;
  }
  
  DailyResetService._internal();
  
  Timer? _resetTimer;
  
  /// Initialize the daily reset service
  void initialize() {
    // Schedule the first reset
    _scheduleNextReset();
  }
  
  /// Schedule the next reset at midnight
  void _scheduleNextReset() {
    // Calculate time until midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);
    
    devPrint('🕛 Scheduling daily reset in ${timeUntilMidnight.inHours} hours and ${timeUntilMidnight.inMinutes % 60} minutes');
    
    // Cancel any existing timer
    _resetTimer?.cancel();
    
    // Schedule the reset
    _resetTimer = Timer(timeUntilMidnight, () {
      _performDailyReset();
      
      // Schedule the next reset
      _scheduleNextReset();
    });
  }
  
  /// Perform daily reset operations
  Future<void> _performDailyReset() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    devPrint('🔄 Performing daily reset operations at midnight');
    devPrint('   Current time: ${now.toString()}');
    devPrint('   New day: ${today.toString().split(' ')[0]}');
    
    // Reset medication notifications
    final medicationNotificationService = MedicationNotificationService();
    medicationNotificationService.resetDailyNotifications();
    devPrint('   ✅ Cleared notification tracking');
    
    // CRITICAL FIX: Reschedule notifications for the new day
    // After midnight, we need to schedule notifications for today's medications
    try {
      devPrint('🔄 Loading medications for the new day: ${today.toString().split(' ')[0]}');
      final journalLog = JournalLog();
      
      // Force reload to ensure we get fresh data for the new day
      final todayMeds = await journalLog.getMedicationsForTheDay(today, forceReload: true);
      
      devPrint('   Found ${todayMeds.length} medications scheduled for today');
      
      // Filter to only include medications with future times (not past times from yesterday)
      final futureMeds = todayMeds.where((med) {
        final timeOfDay = med.treatment.treatmentPlan.timeOfDay;
        final scheduledTime = DateTime(today.year, today.month, today.day, timeOfDay.hour, timeOfDay.minute);
        final isFuture = scheduledTime.isAfter(now);
        
        if (!isFuture) {
          devPrint('   Skipping past time: ${med.treatment.medicine.name} at ${timeOfDay.hour}:${timeOfDay.minute.toString().padLeft(2, '0')}');
        }
        
        return isFuture;
      }).toList();
      
      devPrint('   Scheduling notifications for ${futureMeds.length} future medications');
      await medicationNotificationService.showUntakenMedicationNotifications(futureMeds);
      devPrint('✅ Rescheduled ${futureMeds.length} medication notifications for the new day');
    } catch (e) {
      devPrint('❌ Error rescheduling notifications at midnight: $e');
    }
    
    devPrint('✅ Daily reset completed');
  }
  
  /// Manual trigger for testing purposes
  /// This allows you to test the daily reset logic without waiting for midnight
  Future<void> testDailyReset() async {
    devPrint('🧪 TEST: Manually triggering daily reset');
    await _performDailyReset();
  }
  
  /// Dispose of resources
  void dispose() {
    _resetTimer?.cancel();
  }
}
