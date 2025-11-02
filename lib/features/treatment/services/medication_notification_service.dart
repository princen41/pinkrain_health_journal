import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/data/journal_log.dart';
import 'package:pinkrain/features/journal/domain/push_notifications.dart' as notification_impl;
import 'package:pinkrain/features/treatment/services/medication_scheduler_service.dart';

/// Service to handle medication notifications
/// This service uses the NotificationService from push_notifications.dart
/// to show notifications for untaken medications
class MedicationNotificationService {
  static final MedicationNotificationService _instance =
      MedicationNotificationService._internal();

  factory MedicationNotificationService() {
    return _instance;
  }

  MedicationNotificationService._internal();

  // Use the existing notification service implementation
  final _notificationService = notification_impl.NotificationService();
  
  // Use the new scheduler service for scheduling notifications
  final _schedulerService = MedicationSchedulerService();

  // Track which medications we've already notified for today
  final Set<String> _notifiedMedicationIds = {};
  
  // Track last scheduling time to prevent duplicate rapid schedules
  DateTime? _lastScheduleTime;
  int? _lastMedicationCount;
  static const Duration _scheduleDebounceTime = Duration(seconds: 2);

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize the notification service
    await _notificationService.initialize();
    
    // Initialize the scheduler service
    await _schedulerService.initialize();

    // Check and print notification permission status
    final isEnabled = await areNotificationsEnabled();
    devPrint('🔔 Notifications enabled: $isEnabled');
  }

  /// Check if notifications are enabled for this app
  Future<bool> areNotificationsEnabled() async {
    // Platform-specific logic
    final status = await Permission.notification.status;
    // iOS: rely on permission status (Android system check API not available here)
    if (Platform.isIOS) {
      devPrint('🔍 iOS notification check - Permission: $status');
      return status.isGranted;
    }

    // Android: use system-enabled check
    final systemEnabled = await _notificationService.areNotificationsEnabled();
    devPrint('🔍 Android notification check - System: $systemEnabled, Permission: $status');
    return systemEnabled;
  }

  /// Request notification permissions by directly triggering the Android system dialog
  Future<void> requestNotificationPermissions() async {
    try {
      devPrint('🔔 Requesting notification permissions using permission_handler...');
      
      // Request notification permission using permission_handler
      // This will show the system dialog on Android 13+
      final PermissionStatus status = await Permission.notification.request();
      
      devPrint('🔔 Permission request result: $status');
      
      if (status.isGranted) {
        devPrint('✅ Notification permission granted');
      } else if (status.isDenied) {
        devPrint('❌ Notification permission denied');
      } else if (status.isPermanentlyDenied) {
        devPrint('❌ Notification permission permanently denied. User needs to enable from settings');
      }
      
      // Double-check permission status
      final isEnabled = await areNotificationsEnabled();
      devPrint('🔔 After permission request, notifications enabled: $isEnabled');
    } catch (e) {
      devPrint('❌ Error requesting notification permissions: $e');
      
      // Fall back to the original method if permission_handler fails
      try {
        // Create a simple test notification that will trigger the permission request
        final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);
        
        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'pill_channel_id',
          'Pill Reminders',
          channelDescription: 'Reminders for taking your pills',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
        );
        
        final NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
        );
        
        // Show a notification which will trigger the system permission dialog
        await FlutterLocalNotificationsPlugin().show(
          0,  // ID
          'Permission Request', // Title 
          'Please allow notifications for medication reminders', // Body
          notificationDetails,
        );
      } catch (e2) {
        devPrint('❌ Error with fallback notification permission method: $e2');
      }
    }
  }

  /// Show notifications for untaken medications
  /// This will show immediate notifications for overdue medications (>5 min late)
  /// and schedule notifications for upcoming medications at their exact scheduled times
  Future<void> showUntakenMedicationNotifications(
      List<IntakeLog> medications, {
        bool forceReschedule = false,
        bool showImmediateNotifications = true,
      }) async {
    // DEBOUNCE: Prevent duplicate rapid scheduling (unless forced)
    final now = DateTime.now();
    if (!forceReschedule && _lastScheduleTime != null) {
      final timeSinceLastSchedule = now.difference(_lastScheduleTime!);
      if (timeSinceLastSchedule < _scheduleDebounceTime) {
        // Only skip if medication count hasn't changed (ensures new treatments trigger reschedule)
        final untakenCount = medications.where((med) => !med.isTaken && !med.isSkipped).length;
        if (_lastMedicationCount == untakenCount) {
          devPrint('⏸️ Skipping duplicate request (${timeSinceLastSchedule.inMilliseconds}ms since last)');
          return;
        } else {
          devPrint('🔄 Medication count changed: $_lastMedicationCount → $untakenCount');
        }
      }
    }
    
    _lastScheduleTime = now;
    
    // Skip permission check—rely on system to handle permission errors
    // (Test notifications work, so permissions are granted; our check has false negatives)
    devPrint('🔔 Scheduling notifications at ${now.toString()}');
    devPrint('   (trusting system permission handling)');

    // Print debug info
    devPrint('📋 Checking ${medications.length} medications for notifications');
    int untakenCount = medications.where((med) => !med.isTaken).length;
    int unskippedCount = medications.where((med) => !med.isSkipped).length;
    int untakenUnskippedCount = medications.where((med) => !med.isTaken && !med.isSkipped).length;
    devPrint('   Untaken: $untakenCount, Unskipped: $unskippedCount, Both: $untakenUnskippedCount');
    
    // Track medication count for debounce logic
    _lastMedicationCount = untakenUnskippedCount;

    // First, schedule notifications for future medications
    await _schedulerService.scheduleMedicationNotifications(medications);
    
    // Then show immediate notifications for overdue medications (only if requested)
    // We DON'T want to show immediate notifications when just rescheduling after edits
    if (showImmediateNotifications) {
      await _showImmediateNotificationsForOverdueMedications(medications);
    } else {
      devPrint('⏭️ Skipping immediate notifications (scheduling only)');
    }
    
    devPrint('✅ Notification scheduling completed');
  }
  
  /// Show immediate notifications for medications that are overdue
  Future<void> _showImmediateNotificationsForOverdueMedications(List<IntakeLog> medications) async {
    // Start with a high ID to avoid conflicts with scheduled notifications
    int notificationId = 10000;
    final now = DateTime.now();
    
    devPrint('🔔 Checking for overdue medications to notify immediately');
    int overdueCount = 0;
    
    for (var medication in medications) {
      // Only show notifications for untaken medications
      if (!medication.isTaken) {
        // Create unique ID using full date (YYYYMMDD) and time (HHMM) to prevent conflicts
        final dateKey = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        final DateTime timeSource = medication.doseTime ?? medication.treatment.treatmentPlan.timeOfDay;
        final timeKey = '${timeSource.hour.toString().padLeft(2, '0')}${timeSource.minute.toString().padLeft(2, '0')}';
        final treatmentId = medication.treatment.id;
        final String medicationId;
        if (treatmentId.isNotEmpty) {
          medicationId = '${treatmentId}_${dateKey}_$timeKey';
        } else {
          // Fallback: use medicine name + start timestamp
          final startTimestamp = medication.treatment.treatmentPlan.startDate.millisecondsSinceEpoch;
          medicationId = '${medication.treatment.medicine.name}_${startTimestamp}_${dateKey}_$timeKey';
        }
        
        // Check if we've already notified for this medication today
        if (!_notifiedMedicationIds.contains(medicationId)) {
          // Only show immediate notifications for overdue medications (>5 min past scheduled time)
          bool isOverdue = false;
          
          // Use the specific doseTime if available (for multi-dose treatments)
          final DateTime timeSource = medication.doseTime ?? medication.treatment.treatmentPlan.timeOfDay;
          try {
            // Extract hour and minute from the timeOfDay DateTime
            final hour = timeSource.hour;
            final minute = timeSource.minute;
            
            final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
            // Consider medication overdue if it's more than 5 minutes past scheduled time
            // This gives a grace period for scheduled notifications to fire first
            final timePastScheduled = now.difference(scheduledTime);
            isOverdue = timePastScheduled > const Duration(minutes: 5);
          } catch (e) {
            devPrint('❌ Error parsing scheduled time: $e');
            // Default to showing notification if we can't parse the time
            isOverdue = true;
          }
          
          if (isOverdue) {
            devPrint('🔔 Showing immediate notification for overdue medication: ${medication.treatment.medicine.name}');
            
            // Format the specific dose time for the notification
            final String scheduledTimeStr = '${timeSource.hour.toString().padLeft(2, '0')}:${timeSource.minute.toString().padLeft(2, '0')}';
            
            await _showMedicationNotification(
              id: notificationId,
              title: '${medication.treatment.medicine.name} was scheduled for $scheduledTimeStr',
              body: "You haven't taken your medication yet!",
              medicationId: medicationId,
            );
            
            overdueCount++;
            notificationId++;
          } else {
            devPrint('⏳ Medication ${medication.treatment.medicine.name} will fire at scheduled time');
          }
        } else {
          devPrint('🔕 Already notified for: ${medication.treatment.medicine.name}');
        }
      }
    }
    
    devPrint('📊 Immediate notification summary: $overdueCount overdue (upcoming medications will fire at their scheduled times)');
  }

  /// Show a notification for a medication
  Future<void> _showMedicationNotification({
    required int id,
    required String title,
    required String body,
    required String medicationId,
  }) async {
    try {
      // Show the notification
      await _notificationService.showNotification(
        id,
        title,
        body,
        payload: {
          'medicationId': medicationId,
          'notificationId': id.toString(),
          'medicationName': medicationId.split('_').first, // Extract medicine name from the ID
        },
        includeSnoozeAction: true, // Enable snooze button
      );
      
      // Add to our tracking set to avoid duplicates
      _notifiedMedicationIds.add(medicationId);
      
      devPrint('✅ Showed medication notification for: $medicationId');
    } catch (e) {
      devPrint('❌ Error showing notification: $e');
    }
  }

  /// Clear notification tracking for a specific medication
  /// Call this when a medication's schedule is changed
  void clearNotificationForMedication(String medicationId) {
    // Remove all entries that start with this medication ID
    _notifiedMedicationIds.removeWhere((id) => id.startsWith(medicationId));
    devPrint('🧹 Cleared notification tracking for: $medicationId');
  }
  
  /// Clear all notification tracking (useful when rescheduling)
  void clearAllNotificationTracking() {
    _notifiedMedicationIds.clear();
    _lastScheduleTime = null;
    _lastMedicationCount = null;
    devPrint('🧹 Cleared all notification tracking');
  }
  
  /// Clear notification tracking at the end of the day
  void resetDailyNotifications() {
    _notifiedMedicationIds.clear();
    _lastScheduleTime = null;
    _lastMedicationCount = null;
    _schedulerService.resetScheduledNotifications();
  }
  
  /// Cancel and remove all scheduled notifications for a specific treatment
  /// This should be called when a treatment is deleted
  Future<void> cancelNotificationsForTreatment(String treatmentId) async {
    await _schedulerService.cancelNotificationsForTreatment(treatmentId);
    clearNotificationForMedication(treatmentId);
  }
  
  /// Debug: Print all scheduled notifications
  /// Useful for troubleshooting notification issues
  Future<void> debugPrintScheduledNotifications() async {
    await _schedulerService.debugPrintScheduledNotifications();
  }
  
  /// One-time cleanup: Remove duplicate notification records
  /// This can be called once to fix existing duplicate issues
  Future<int> cleanupDuplicateNotifications() async {
    return await _schedulerService.cleanupDuplicateNotifications();
  }
}
