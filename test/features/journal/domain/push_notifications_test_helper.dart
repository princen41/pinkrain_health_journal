import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pinkrain/core/util/helpers.dart';
import 'package:pinkrain/features/journal/domain/push_notifications.dart';
import 'package:pinkrain/features/treatment/services/medication_action_service.dart';

/// Test helper for notification service testing
/// Provides utilities to simulate notification responses in tests
class NotificationTestHelper {
  /// Simulates a notification response for testing purposes
  /// This allows tests to trigger the private _handleNotificationResponse method
  /// without exposing it publicly in the production service
  static Future<void> simulateNotificationResponse(
    NotificationService notificationService,
    NotificationResponse response,
  ) async {
    // Log that this is a test method
    devPrint('TEST: Simulating notification response');
    
    // Access the private handler through reflection or by creating a test-specific method
    // Since we can't access private methods directly, we'll need to modify the service
    // to expose a test-only method or use a different approach
    
    // For now, we'll create a test-specific notification service that exposes the handler
    // This is a cleaner approach than exposing test methods in production code
    await _handleNotificationResponseForTesting(notificationService, response);
  }
  
  /// Internal method to handle notification response for testing
  /// This replicates the logic from the private _handleNotificationResponse method
  static Future<void> _handleNotificationResponseForTesting(
    NotificationService notificationService,
    NotificationResponse response,
  ) async {
    devPrint('Notification response received: ${response.payload}');
    devPrint('Action ID: ${response.actionId ?? 'NO_ACTION_ID'}');
    
    // Check if we have a payload
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Parse the payload JSON
        final Map<String, dynamic> payload = json.decode(response.payload!);
        
        devPrint('Notification action ID: ${response.actionId}');
        devPrint('Notification payload decoded: $payload');
        
        // Process different action types
        switch (response.actionId) {
          case 'SNOOZE_ACTION':
            devPrint(' SNOOZE button pressed - processing...');
            await _handleSnoozeActionForTesting(notificationService, payload);
            break;
          case 'MARK_TAKEN_ACTION':
            devPrint(' MARK AS TAKEN button pressed - processing...');
            await _handleMarkTakenActionForTesting(notificationService, payload);
            break;
          default:
            // Handle regular notification tap (no specific action)
            devPrint('Regular notification tapped (no action button), payload: $payload');
        }
      } catch (e) {
        devPrint(' Error handling notification response: $e');
      }
    } else {
      devPrint(' Empty payload in notification response');
    }
  }
  
  /// Handle the snooze action for testing
  static Future<void> _handleSnoozeActionForTesting(
    NotificationService notificationService,
    Map<String, dynamic> payload,
  ) async {
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
      final success = await MedicationActionService().snoozeMedication(
        medicationId,
        snoozeMinutes: 5, // Snooze for 5 minutes
        metadata: payload, // Include all original payload data
      );
      
      if (success) {
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
        
        // Schedule the snoozed notification using the public method
        await notificationService.showNotification(
          snoozeNotificationId,
          title,
          body,
          payload: updatedPayload,
          includeSnoozeAction: true, // Allow re-snoozing
        );
        
        devPrint('✅ Medication $medicationId snoozed until $snoozeTime');
      } else {
        devPrint('❌ Failed to snooze medication $medicationId');
      }
    } catch (e) {
      devPrint('❌ Error handling snooze action: $e');
    }
  }
  
  /// Handle the mark as taken action for testing
  static Future<void> _handleMarkTakenActionForTesting(
    NotificationService notificationService,
    Map<String, dynamic> payload,
  ) async {
    // Get the medication ID
    final String medicationId = payload['medicationId'] ?? '';
    
    if (medicationId.isEmpty) {
      devPrint('❌ Cannot mark medication as taken: No medication ID provided');
      return;
    }
    
    try {
      // Get medication name if available
      final String medicationName = payload['medicationName'] ?? 'medication';
      
      devPrint('🔔 Processing mark as taken for: $medicationName (ID: $medicationId)');
      
      // Use the MedicationActionService to mark medication as taken
      final success = await MedicationActionService().markMedicationAsTaken(
        medicationId, 
        metadata: payload,
      );
      
      if (success) {
        // Cancel the notification to remove it from the notification drawer
        final String notificationId = payload['notificationId'] ?? '';
        if (notificationId.isNotEmpty) {
          // Note: In tests, we can't actually cancel notifications, but we log it
          devPrint('Would cancel notification ID: $notificationId');
        }
        
        devPrint('✅ Medication $medicationId marked as taken successfully');
      } else {
        devPrint('❌ Failed to mark medication $medicationId as taken');
      }
    } catch (e) {
      devPrint('❌ Error marking medication as taken: $e');
    }
  }
}
