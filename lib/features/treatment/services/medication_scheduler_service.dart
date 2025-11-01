import 'dart:io';
import 'package:hive/hive.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/data/journal_log.dart';
import 'package:pinkrain/features/journal/domain/push_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// Service responsible for scheduling medication notifications
/// This service follows clean architecture principles by:
/// 1. Using a separate service for scheduling logic
/// 2. Persisting notification data via Hive
/// 3. Maintaining proper separation of concerns
class MedicationSchedulerService {
  static final MedicationSchedulerService _instance = MedicationSchedulerService._internal();
  
  factory MedicationSchedulerService() {
    return _instance;
  }
  
  MedicationSchedulerService._internal();
  
  static const String _boxName = 'medication_scheduler';
  static const String _scheduledNotificationsKey = 'scheduled_notifications';
  static const String _reminderOffsetKey = 'reminder_offset_minutes';
  
  // Default reminder time (15 minutes before medication is due)
  static const int _defaultReminderOffsetMinutes = 15;
  
  final NotificationService _notificationService = NotificationService();
  
  /// Initialize the scheduler service
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    
    // Make sure the notification service is initialized
    await _notificationService.initialize();
    
    // Open Hive box for persistent storage
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    
    // Reset notifications that have passed
    await _cleanupPassedNotifications();
    
    // Restore scheduled notifications on app restart
    // iOS clears scheduled notifications when the app is killed, so we need to reschedule them
    await _restoreScheduledNotifications();
  }
  
  /// Get the configured reminder offset in minutes
  /// This is how many minutes before the scheduled time the reminder will be sent
  Future<int> getReminderOffsetMinutes() async {
    final box = await _getBox();
    final offsetMinutes = box.get(_reminderOffsetKey, defaultValue: _defaultReminderOffsetMinutes);
    return offsetMinutes;
  }
  
  /// Set the reminder offset in minutes
  /// This is how many minutes before the scheduled time the reminder will be sent
  Future<void> setReminderOffsetMinutes(int minutes) async {
    if (minutes < 0) {
      throw ArgumentError('Reminder offset cannot be negative');
    }
    
    final box = await _getBox();
    await box.put(_reminderOffsetKey, minutes);
  }
  
  /// Schedule notifications for medications
  /// This method will schedule notifications for each medication
  /// based on its scheduled time
  Future<void> scheduleMedicationNotifications(List<IntakeLog> medications) async {
    devPrint('📅 Scheduling notifications for ${medications.length} medications');
    
    // Get the box for storing notification data
    final box = await _getBox();
    
    // CRITICAL FIX: Clean up passed notifications FIRST to avoid rescheduling old ones
    await _cleanupPassedNotifications();
    
    // Get existing scheduled notifications (after cleanup)
    final scheduledNotifications = _getScheduledNotifications(box);
    
    // Cancel all existing scheduled notifications to prevent duplicates
    devPrint('🧹 Canceling ${scheduledNotifications.length} existing notifications to prevent duplicates');
    for (var notification in scheduledNotifications) {
      final int id = notification['id'];
      try {
        await _notificationService.cancelReminder(id);
      } catch (e) {
        devPrint('⚠️ Error canceling notification $id: $e');
      }
    }
    
    // Track newly scheduled notifications
    final List<Map<String, dynamic>> newScheduledNotifications = [];
    
    // Get the reminder offset
    final reminderOffsetMinutes = await getReminderOffsetMinutes();
    
    DateTime now = DateTime.now();
    
    for (var medication in medications) {
      // Only schedule for untaken and unskipped medications
      if (!medication.isTaken && !medication.isSkipped) {
        // Get the scheduled time for this medication
        final scheduledTime = _getScheduledTimeForMedication(medication);
        
        // CRITICAL: Don't reschedule past doses to tomorrow
        // Missed doses should stay in the past - only schedule future notifications
        if (scheduledTime.isBefore(now)) {
          devPrint('⏭️ Skipping past dose: ${medication.treatment.medicine.name} was scheduled for ${scheduledTime.toString()}');
          devPrint('   (Missed doses stay in the past - immediate notifications will handle overdue reminders)');
          continue; // Skip this medication
        }
        
        // Create a unique ID for this medication
        // CRITICAL FIX: Use full date (YYYYMMDD) instead of just day number to prevent cross-day conflicts
        final dateKey = '${scheduledTime.year}${scheduledTime.month.toString().padLeft(2, '0')}${scheduledTime.day.toString().padLeft(2, '0')}';
        final treatmentId = medication.treatment.id;
        final medicationId = treatmentId.isNotEmpty 
            ? '${treatmentId}_$dateKey'
            : '${medication.treatment.medicine.name}_$dateKey';
        
        // Generate a random ID for the notification
        final notificationId = _generateNotificationId();
        
        // Calculate the reminder time (before the scheduled time)
        final reminderTime = scheduledTime.subtract(Duration(minutes: reminderOffsetMinutes));
        
        // Only schedule reminder if it's in the future
        if (reminderTime.isAfter(now)) {
          // Schedule the reminder notification
          final reminderNotificationId = _generateNotificationId();
          await _scheduleNotification(
            id: reminderNotificationId,
            title: '${medication.treatment.medicine.name} in $reminderOffsetMinutes minutes... 💊',
            body: 'Don\'t forget to take your medication!',
            scheduledTime: reminderTime,
            payload: {
              'medicationId': medicationId,
              'type': 'reminder',
              'reminderNotificationId': reminderNotificationId.toString(),
              'mainNotificationId': notificationId.toString(),
              'snooze': true,
            },
          );
          
          // Track the scheduled notification
          newScheduledNotifications.add({
            'id': reminderNotificationId,
            'medicationId': medicationId,
            'scheduledTime': reminderTime.millisecondsSinceEpoch,
            'type': 'reminder',
          });
          
          devPrint('🔔 Scheduled reminder for ${medication.treatment.medicine.name} at ${reminderTime.toString()}');
        }
        
        // Schedule the main notification at the exact time
        await _scheduleNotification(
          id: notificationId,
          title: 'Take your ${medication.treatment.medicine.name}',
          body: '⏳ Time for your medication!',
          scheduledTime: scheduledTime,
          payload: {
            'medicationId': medicationId,
            'type': 'main',
            'notificationId': notificationId.toString(),
            'snooze': true,
          },
        );
        
        // Track the scheduled notification
        newScheduledNotifications.add({
          'id': notificationId,
          'medicationId': medicationId,
          'scheduledTime': scheduledTime.millisecondsSinceEpoch,
          'type': 'main',
        });
        
        devPrint('🔔 Scheduled notification for ${medication.treatment.medicine.name} at ${scheduledTime.toString()}');
      }
    }
    
    // Since we canceled all old notifications, just save the new ones
    // Deduplicate the new notifications just in case
    final Map<String, Map<String, dynamic>> uniqueNotifications = {};
    
    for (final notification in newScheduledNotifications) {
      // IMPROVED DEDUPLICATION: Use medicationId, type, and scheduled time as composite key
      // This ensures we don't have duplicate notifications for the same medication at the same time
      final String compositeKey = '${notification['medicationId']}_${notification['type']}_${notification['scheduledTime']}';
      
      // Keep the notification with the higher ID (more recent) if there are duplicates
      if (!uniqueNotifications.containsKey(compositeKey) || 
          notification['id'] > uniqueNotifications[compositeKey]!['id']) {
        uniqueNotifications[compositeKey] = notification;
      }
    }
    
    // Convert back to list for saving
    final deduplicatedNotifications = uniqueNotifications.values.toList();
    
    devPrint('💾 Saving ${deduplicatedNotifications.length} scheduled notifications (removed ${newScheduledNotifications.length - deduplicatedNotifications.length} duplicates)');
    
    // Save the updated list of scheduled notifications
    await _saveScheduledNotifications(box, deduplicatedNotifications);
  }
  
  /// Clean up notifications that have already passed
  Future<void> _cleanupPassedNotifications() async {
    final box = await _getBox();
    final scheduledNotifications = _getScheduledNotifications(box);
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    
    // Filter out notifications that have already passed (with 1 minute buffer to be safe)
    final activeNotifications = scheduledNotifications.where((notification) {
      final scheduledMs = notification['scheduledTime'] as int;
      return scheduledMs > nowMs;
    }).toList();
    
    final removedCount = scheduledNotifications.length - activeNotifications.length;
    if (removedCount > 0) {
      devPrint('🧹 Cleaned up $removedCount passed notifications');
      
      // Also cancel these from the system notification manager
      for (var notification in scheduledNotifications) {
        final scheduledMs = notification['scheduledTime'] as int;
        if (scheduledMs <= nowMs) {
          final int id = notification['id'];
          final medicationId = notification['medicationId'] ?? 'unknown';
          final scheduledDate = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
          devPrint('   Removing past notification: $medicationId scheduled for ${scheduledDate.toString()}');
          try {
            await _notificationService.cancelReminder(id);
          } catch (e) {
            devPrint('   ⚠️ Error canceling past notification $id: $e');
          }
        }
      }
      
      await _saveScheduledNotifications(box, activeNotifications);
    }
  }
  
  /// Restore scheduled notifications from Hive storage
  /// This is critical for iOS where notifications are cleared when the app is killed
  Future<void> _restoreScheduledNotifications() async {
    try {
      final box = await _getBox();
      final scheduledNotifications = _getScheduledNotifications(box);
      
      if (scheduledNotifications.isEmpty) {
        devPrint('📭 No stored notifications to restore');
        return;
      }
      
      devPrint('🔄 Restoring ${scheduledNotifications.length} scheduled notifications from storage');
      
      // Group notifications by medication ID to reconstruct the full medication data
      final Map<String, List<Map<String, dynamic>>> notificationsByMedicationId = {};
      
      for (var notification in scheduledNotifications) {
        final medicationId = notification['medicationId'] as String? ?? '';
        if (medicationId.isNotEmpty) {
          notificationsByMedicationId.putIfAbsent(medicationId, () => []);
          notificationsByMedicationId[medicationId]!.add(notification);
        }
      }
      
      // Reschedule each notification
      for (var notification in scheduledNotifications) {
        try {
          final int id = notification['id'];
          final String medicationId = notification['medicationId'] ?? '';
          final int scheduledTimeMs = notification['scheduledTime'];
          final String type = notification['type'] ?? 'main';
          
          final scheduledTime = DateTime.fromMillisecondsSinceEpoch(scheduledTimeMs);
          
          // Only reschedule if the notification is still in the future
          if (scheduledTime.isAfter(DateTime.now())) {
            // Extract medication name from the ID
            final medicationName = medicationId.split('_').first;
            
            // Determine title and body based on notification type
            String title;
            String body;
            
            if (type == 'reminder') {
              // Get reminder offset for the title
              final reminderOffsetMinutes = await getReminderOffsetMinutes();
              title = '$medicationName in $reminderOffsetMinutes minutes... 💊';
              body = 'Don\'t forget to take your medication!';
            } else {
              title = 'Take your $medicationName';
              body = '⏳ Time for your medication!';
            }
            
            // Reschedule the notification
            await _scheduleNotification(
              id: id,
              title: title,
              body: body,
              scheduledTime: scheduledTime,
              payload: {
                'medicationId': medicationId,
                'type': type,
                'notificationId': id.toString(),
                'medicationName': medicationName,
                'snooze': true,
              },
            );
            
            devPrint('✅ Restored notification: $title for $scheduledTime');
          } else {
            devPrint('⏰ Skipping past notification: $medicationId at $scheduledTime');
          }
        } catch (e) {
          devPrint('❌ Error restoring individual notification: $e');
        }
      }
      
      devPrint('✅ Finished restoring scheduled notifications');
    } catch (e) {
      devPrint('❌ Error restoring scheduled notifications: $e');
    }
  }
  
  /// Schedule a notification to be shown at a specific time
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // Make sure the payload includes a medicationName field for snooze handling
      if (!payload.containsKey('medicationName') && payload.containsKey('medicationId')) {
        // Extract medication name from the ID if available
        final String medicationId = payload['medicationId'] ?? '';
        if (medicationId.isNotEmpty && medicationId.contains('_')) {
          payload['medicationName'] = medicationId.split('_').first;
        }
      }

      // Schedule the notification
      // This works on both iOS and Android - iOS uses DarwinNotificationDetails
      // with presentAlert: true, presentBadge: true, presentSound: true
      await _notificationService.schedulePillReminder(
        id,
        title,
        body,
        scheduledTime,
        payload: payload,
      );
      
      devPrint('✅ Scheduled notification: $title for $scheduledTime');
      if (Platform.isIOS) {
        devPrint('📱 iOS: Notification scheduled and will appear on lock screen/notification center');
      }
    } catch (e) {
      devPrint('❌ Error scheduling notification: $e');
    }
  }
  
  /// Get the scheduled time for a medication
  /// Returns the scheduled time for TODAY only (doesn't reschedule to tomorrow)
  /// Caller is responsible for checking if time is in the past
  DateTime _getScheduledTimeForMedication(IntakeLog medication) {
    // Try to get the scheduled time from the medication
    final timeOfDay = medication.treatment.treatmentPlan.timeOfDay;
    try {
      // Extract hour and minute from the timeOfDay DateTime
      final hour = timeOfDay.hour;
      final minute = timeOfDay.minute;
      
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      devPrint('⏰ Medication: ${medication.treatment.medicine.name}, Current time: ${now.toString()}, Scheduled time: ${scheduledTime.toString()}');
      
      // Just return the time for today - don't reschedule past doses
      // The calling code will handle skipping past times
      if (scheduledTime.isBefore(now)) {
        devPrint('📅 Time is in the past (will be skipped by caller)');
      } else {
        devPrint('✅ Time is in the future');
      }
      
      return scheduledTime;
    } catch (e) {
      devPrint('❌ Error parsing scheduled time: $e');
    }
    
    // Default: schedule for 1 hour from now
    final defaultTime = DateTime.now().add(const Duration(hours: 1));
    devPrint('⚠️ Using default time (1 hour from now): ${defaultTime.toString()}');
    return defaultTime;
  }
  
  /// Generate a unique notification ID for a medication
  int _generateNotificationId() {
    // Use the treatment ID as part of the notification ID to ensure uniqueness
    // Add a timestamp component to avoid conflicts
    final baseId = DateTime.now().millisecondsSinceEpoch;
    final timeComponent = DateTime.now().millisecondsSinceEpoch % 10000;
    
    // Combine them while ensuring we stay within 32-bit integer range
    return (baseId % 100000) * 10000 + timeComponent;
  }
  
  /// Get the Hive box for notification storage
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }
  
  /// Get the list of scheduled notifications from Hive
  List<Map<String, dynamic>> _getScheduledNotifications(Box box) {
    final data = box.get(_scheduledNotificationsKey);
    if (data == null) {
      return [];
    }
    
    try {
      // Properly convert from dynamic Hive data to typed List<Map<String, dynamic>>
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            // Convert each map to ensure keys are strings
            return item.map((key, value) => MapEntry(key.toString(), value));
          }
          return <String, dynamic>{};
        }).toList();
      }
      devPrint('❌ Invalid data format in Hive storage: expected List but got ${data.runtimeType}');
      return [];
    } catch (e) {
      devPrint('❌ Error retrieving scheduled notifications: $e');
      return [];
    }
  }
  
  /// Save the list of scheduled notifications to Hive
  Future<void> _saveScheduledNotifications(Box box, List<Map<String, dynamic>> notifications) async {
    await box.put(_scheduledNotificationsKey, notifications);
  }
  
  /// Reset scheduled notifications at midnight
  /// This should be called daily to ensure notifications are refreshed
  Future<void> resetScheduledNotifications() async {
    final box = await _getBox();
    await box.put(_scheduledNotificationsKey, []);
    devPrint('🔄 Reset scheduled notifications');
  }
  
  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    final box = await _getBox();
    final scheduledNotifications = _getScheduledNotifications(box);
    
    for (var notification in scheduledNotifications) {
      final int id = notification['id'];
      await _notificationService.cancelReminder(id);
    }
    
    await resetScheduledNotifications();
    devPrint('❌ Cancelled all scheduled notifications');
  }
}
