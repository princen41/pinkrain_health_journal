import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/util/helpers.dart';
import '../../../features/treatment/services/medication_action_service.dart';

/// Strategy interface for scheduling notifications
/// This allows the handler to schedule notifications without depending on NotificationService directly
abstract class NotificationScheduler {
  Future<void> scheduleNotification(
    int id,
    String title,
    String body, {
    Map<String, dynamic>? payload,
    bool includeSnoozeAction = true,
  });
  
  Future<void> cancelNotification(int id);
}

/// Handles notification responses including action buttons (Snooze, Mark as Taken)
/// Extracted from NotificationService for improved testability
class NotificationResponseHandler {
  final MedicationActionService _medicationActionService;
  final NotificationScheduler? _notificationScheduler;
  
  /// Creates a handler with required dependencies
  /// [medicationActionService] handles medication state changes
  /// [notificationScheduler] optional scheduler for snooze functionality (can be null for tests)
  NotificationResponseHandler({
    MedicationActionService? medicationActionService,
    NotificationScheduler? notificationScheduler,
  })  : _medicationActionService = medicationActionService ?? MedicationActionService(),
        _notificationScheduler = notificationScheduler;
  
  /// Handle notification responses, including action buttons
  /// This method surfaces errors so tests can assert on them
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    devPrint('Notification response received: ${response.payload}');
    devPrint('Action ID: ${response.actionId ?? 'NO_ACTION_ID'}');
    
    // Check if we have a payload
    if (response.payload != null && response.payload!.isNotEmpty) {
      // Parse the payload JSON - let exceptions bubble up for testing
      final Map<String, dynamic> payload = json.decode(response.payload!);
      
      devPrint('Notification action ID: ${response.actionId}');
      devPrint('Notification payload decoded: $payload');
      
      // Process different action types
      switch (response.actionId) {
        case 'SNOOZE_ACTION':
          devPrint('🔔 SNOOZE button pressed - processing...');
          await handleSnoozeAction(payload);
          break;
        case 'MARK_TAKEN_ACTION':
          devPrint('💊 MARK AS TAKEN button pressed - processing...');
          await handleMarkTakenAction(payload);
          break;
        default:
          // Handle regular notification tap (no specific action)
          devPrint('Regular notification tapped (no action button), payload: $payload');
      }
    } else {
      devPrint('⚠️ Empty payload in notification response');
    }
  }
  
  /// Handle the snooze action
  @visibleForTesting
  Future<void> handleSnoozeAction(Map<String, dynamic> payload) async {
    // Get the notification ID and medication ID
    final String medicationId = payload['medicationId'] ?? '';
    
    if (medicationId.isEmpty) {
      devPrint('❌ Cannot snooze: No medication ID provided in payload');
      return;
    }
    
    try {
      // Get medication data from payload
      final String notificationId = payload['notificationId'] ?? '';
      final String medicationName = payload['medicationName'] ?? 'medication';
      
      devPrint('🔔 Processing snooze for medication: $medicationName (ID: $medicationId)');
      
      // Use the MedicationActionService to snooze this medication
      final success = await _medicationActionService.snoozeMedication(
        medicationId,
        snoozeMinutes: 5, // Snooze for 5 minutes
        metadata: payload, // Include all original payload data
      );
      
      if (success) {
        // Only schedule new notification if scheduler is provided (production mode)
        final scheduler = _notificationScheduler;
        if (scheduler != null) {
          // Schedule a new notification for 5 minutes from now
          final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
          
          // Create a notification title and body with medication information
          final String title = 'Snoozed: Take your $medicationName';
          final String body = 'This is a snoozed reminder for your medication';
          
          // Add information to payload to indicate this is a snoozed notification
          final Map<String, dynamic> updatedPayload = Map<String, dynamic>.from(payload);
          updatedPayload['isSnoozed'] = true;
          updatedPayload['originalNotificationId'] = notificationId;
          updatedPayload['snoozeTime'] = snoozeTime.toIso8601String();
          
          // Use a consistent ID for the snoozed notification based on the original
          final int snoozeNotificationId = notificationId.isNotEmpty 
              ? int.parse(notificationId) + 1000 // Derived from original ID
              : DateTime.now().millisecondsSinceEpoch % 100000000; // Fallback
          
          // Schedule the snoozed notification
          await scheduler.scheduleNotification(
            snoozeNotificationId,
            title,
            body,
            payload: updatedPayload,
            includeSnoozeAction: true, // Allow re-snoozing
          );
          
          devPrint('✅ Medication $medicationId snoozed until $snoozeTime');
        } else {
          devPrint('✅ Medication $medicationId marked as snoozed (no scheduler for notification)');
        }
      } else {
        devPrint('❌ Failed to snooze medication $medicationId');
      }
    } catch (e) {
      devPrint('❌ Error handling snooze action: $e');
      rethrow; // Re-throw for test assertions
    }
  }
  
  /// Handle the mark as taken action
  @visibleForTesting
  Future<void> handleMarkTakenAction(Map<String, dynamic> payload) async {
    // Get the medication ID
    final String medicationId = payload['medicationId'] ?? '';
    
    if (medicationId.isEmpty) {
      devPrint('❌ Cannot mark medication as taken: No medication ID provided');
      return;
    }
    
    try {
      // Get medication name if available
      final String medicationName = payload['medicationName'] ?? 'medication';
      
      devPrint('💊 Processing mark as taken for: $medicationName (ID: $medicationId)');
      
      // Use the MedicationActionService to mark medication as taken
      final success = await _medicationActionService.markMedicationAsTaken(
        medicationId, 
        metadata: payload,
      );
      
      if (success) {
        // Cancel the notification to remove it from the notification drawer
        // Only if scheduler is provided (production mode)
        final scheduler = _notificationScheduler;
        if (scheduler != null) {
          final String notificationId = payload['notificationId'] ?? '';
          if (notificationId.isNotEmpty) {
            await scheduler.cancelNotification(int.parse(notificationId));
            devPrint('Cancelled notification ID: $notificationId');
          }
        }
        
        devPrint('✅ Medication $medicationId marked as taken successfully');
      } else {
        devPrint('❌ Failed to mark medication $medicationId as taken');
      }
    } catch (e) {
      devPrint('❌ Error marking medication as taken: $e');
      rethrow; // Re-throw for test assertions
    }
  }
}

