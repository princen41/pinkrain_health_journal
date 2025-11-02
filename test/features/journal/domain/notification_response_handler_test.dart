import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinkrain/features/journal/domain/notification_response_handler.dart';
import 'package:pinkrain/features/treatment/services/medication_action_service.dart';

/// Mock notification scheduler for testing
class MockNotificationScheduler implements NotificationScheduler {
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<int> cancelledNotifications = [];
  
  @override
  Future<void> scheduleNotification(
    int id,
    String title,
    String body, {
    Map<String, dynamic>? payload,
    bool includeSnoozeAction = true,
  }) async {
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'includeSnoozeAction': includeSnoozeAction,
    });
  }
  
  @override
  Future<void> cancelNotification(int id) async {
    cancelledNotifications.add(id);
  }
}

/// Mock medication action service for testing
/// This mock simulates MedicationActionService without requiring Hive initialization
class MockMedicationActionService implements MedicationActionService {
  final Map<String, Map<String, dynamic>> medicationStates = {};
  
  // Stub methods for singleton pattern (not used in tests)
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // For methods we don't explicitly mock
    return super.noSuchMethod(invocation);
  }
  
  /// Mock implementation of snoozeMedication
  @override
  Future<bool> snoozeMedication(
    String medicationId, {
    int snoozeMinutes = 5,
    Map<String, dynamic>? metadata,
  }) async {
    medicationStates[medicationId] = {
      'status': 'snoozed',
      'snoozeMinutes': snoozeMinutes,
      'metadata': metadata,
    };
    return true;
  }
  
  /// Mock implementation of markMedicationAsTaken
  @override
  Future<bool> markMedicationAsTaken(
    String medicationId, {
    Map<String, dynamic>? metadata,
  }) async {
    medicationStates[medicationId] = {
      'status': 'taken',
      'metadata': metadata,
    };
    return true;
  }
  
  /// Mock implementation of isMedicationTaken
  @override
  Future<bool> isMedicationTaken(String medicationId) async {
    return medicationStates[medicationId]?['status'] == 'taken';
  }
  
  /// Mock implementation of getMedicationStatus
  @override
  Future<Map<String, dynamic>> getMedicationStatus(String medicationId) async {
    return medicationStates[medicationId] ?? {};
  }
}

void main() {
  group('NotificationResponseHandler', () {
    late NotificationResponseHandler handler;
    late MockNotificationScheduler mockScheduler;
    late MockMedicationActionService mockMedicationService;
    
    setUp(() {
      mockScheduler = MockNotificationScheduler();
      mockMedicationService = MockMedicationActionService();
      handler = NotificationResponseHandler(
        medicationActionService: mockMedicationService,
        notificationScheduler: mockScheduler,
      );
    });
    
    test('handleSnoozeAction marks medication as snoozed and schedules notification', () async {
      // Arrange
      final payload = {
        'medicationId': 'test_med_123',
        'medicationName': 'Test Medication',
        'notificationId': '12345',
      };
      
      // Act
      await handler.handleSnoozeAction(payload);
      
      // Assert - verify a new notification was scheduled
      expect(mockScheduler.scheduledNotifications.length, 1);
      final scheduled = mockScheduler.scheduledNotifications.first;
      expect(scheduled['title'], contains('Snoozed'));
      expect(scheduled['title'], contains('Test Medication'));
      expect(scheduled['includeSnoozeAction'], true);
      
      // Verify payload was updated
      final scheduledPayload = scheduled['payload'] as Map<String, dynamic>;
      expect(scheduledPayload['isSnoozed'], true);
      expect(scheduledPayload['originalNotificationId'], '12345');
      expect(scheduledPayload.containsKey('snoozeTime'), true);
    });
    
    test('handleSnoozeAction without scheduler only marks as snoozed', () async {
      // Arrange - create handler without scheduler but with mock medication service
      final mockServiceNoScheduler = MockMedicationActionService();
      final handlerNoScheduler = NotificationResponseHandler(
        medicationActionService: mockServiceNoScheduler,
        notificationScheduler: null,
      );
      final payload = {
        'medicationId': 'test_med_456',
        'medicationName': 'Test Med 2',
        'notificationId': '67890',
      };
      
      // Act - should not throw, just log
      await handlerNoScheduler.handleSnoozeAction(payload);
      
      // Assert - medication was marked as snoozed
      expect(mockServiceNoScheduler.medicationStates['test_med_456']?['status'], 'snoozed');
      // Assert - no notifications scheduled (no scheduler provided)
      expect(mockScheduler.scheduledNotifications.length, 0);
    });
    
    test('handleMarkTakenAction cancels notification when scheduler provided', () async {
      // Arrange
      final payload = {
        'medicationId': 'test_med_789',
        'medicationName': 'Test Med 3',
        'notificationId': '99999',
      };
      
      // Act
      await handler.handleMarkTakenAction(payload);
      
      // Assert - verify notification was cancelled
      expect(mockScheduler.cancelledNotifications.length, 1);
      expect(mockScheduler.cancelledNotifications.first, 99999);
    });
    
    test('handleNotificationResponse routes to correct handler', () async {
      // Arrange - create a snooze response
      final snoozePayload = {
        'medicationId': 'test_med_abc',
        'medicationName': 'Test Med ABC',
        'notificationId': '11111',
      };
      final snoozeResponse = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: 'SNOOZE_ACTION',
        payload: json.encode(snoozePayload),
      );
      
      // Act
      await handler.handleNotificationResponse(snoozeResponse);
      
      // Assert - verify snooze was processed
      expect(mockScheduler.scheduledNotifications.length, 1);
      
      // Reset
      mockScheduler.scheduledNotifications.clear();
      
      // Arrange - create a mark taken response
      final takenPayload = {
        'medicationId': 'test_med_xyz',
        'medicationName': 'Test Med XYZ',
        'notificationId': '22222',
      };
      final takenResponse = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: 'MARK_TAKEN_ACTION',
        payload: json.encode(takenPayload),
      );
      
      // Act
      await handler.handleNotificationResponse(takenResponse);
      
      // Assert - verify mark taken was processed
      expect(mockScheduler.cancelledNotifications.length, 1);
      expect(mockScheduler.cancelledNotifications.last, 22222);
    });
    
    test('handleNotificationResponse with empty payload does not throw', () async {
      // Arrange
      final emptyResponse = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '',
      );
      
      // Act & Assert - should not throw
      await handler.handleNotificationResponse(emptyResponse);
    });
    
    test('handler can be injected with test double for medication service', () async {
      // This test demonstrates that we can inject a mock MedicationActionService
      // if needed for more advanced testing scenarios
      
      // Arrange - create a custom mock and handler with injected dependencies
      final customMockService = MockMedicationActionService();
      final customMockScheduler = MockNotificationScheduler();
      final customHandler = NotificationResponseHandler(
        medicationActionService: customMockService,
        notificationScheduler: customMockScheduler,
      );
      
      final payload = {
        'medicationId': 'test_injection',
        'medicationName': 'Injectable Med',
        'notificationId': '33333',
      };
      
      // Act
      await customHandler.handleSnoozeAction(payload);
      
      // Assert - handler works with injected dependencies
      expect(customMockScheduler.scheduledNotifications.length, 1);
      expect(customMockService.medicationStates['test_injection']?['status'], 'snoozed');
    });
  });
}

