import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/util/helpers.dart';
import '../../../features/treatment/services/medication_action_service.dart';
import 'notification_response_handler.dart';

class NotificationService implements NotificationScheduler {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService({NotificationResponseHandler? handler}) {
    // Allow handler injection for testing
    if (handler != null) {
      _instance._handler = handler;
    }
    return _instance;
  }

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  late NotificationResponseHandler _handler;

  NotificationService._internal() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    // Initialize handler with self as the scheduler (for production use)
    _handler = NotificationResponseHandler(
      notificationScheduler: this,
    );
  }
  
  /// Exposes the notification response handler for testing purposes
  /// Tests can inject a custom handler or access the real one
  @visibleForTesting
  NotificationResponseHandler get handler => _handler;

  // We'll use this key in getSelectedSoundPath method implementation when SharedPreferences is properly integrated
  static const String selectedSoundKey = 'selected_notification_sound';

  // Get the selected notification sound path from SharedPreferences
  Future<String?> getSelectedSoundPath() async {
    /*final prefs = await SharedPreferences.getInstance();
    return prefs.getString(selectedSoundKey);*/
    return 'pill_alarm';
  }

  Future<void> _init() async {
    // Initialize timezone data first
    tz_data.initializeTimeZones();
    
    // Initialize Android settings with the correct icon
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
      // Create notification categories for iOS with action buttons
    final DarwinNotificationCategory pillReminderCategory = DarwinNotificationCategory(
      'PILL_REMINDER_CATEGORY',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'SNOOZE_ACTION',
          'Snooze',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
        DarwinNotificationAction.plain(
          'MARK_TAKEN_ACTION',
          'Mark as Taken',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
      ],
    );
    
    // Initialize iOS settings with notification categories
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: <DarwinNotificationCategory>[pillReminderCategory],
    );
    
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: Platform.isAndroid ? initializationSettingsAndroid : null,
      iOS: Platform.isIOS ? initializationSettingsIOS : null,
    );
    
    // Handle notification responses including action buttons
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Log the response details to debug
        devPrint('NOTIFICATION ACTION RECEIVED: ${details.actionId}');
        devPrint('NOTIFICATION PAYLOAD RECEIVED: ${details.payload}');
        
        // Pass to the handler
        _handleNotificationResponse(details);
      },
    );
    
    // Ensure iOS shows notifications while app is in foreground (banners/sound)
    final iosImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      devPrint('iOS foreground presentation options requested (alert/badge/sound)');
    }

    // For Android 13+, we need to explicitly check notification permissions
    // but for older versions, we don't need to request permissions
    // so we'll just log the initialization instead
    final AndroidFlutterLocalNotificationsPlugin? androidImpl = 
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      devPrint('Android notification plugin initialized');
    }
    
    // Create notification channel
    await _createNotificationChannel();
    
    // Initialize the medication action service
    await MedicationActionService().initialize();
    
    devPrint('Notification service initialized successfully');
  }

  Future<void> initialize() async {
    await _init();
  }

  /// Handle notification responses, including action buttons
  void _handleNotificationResponse(NotificationResponse response) {
    // Delegate to handler but swallow errors in production
    try {
      _handler.handleNotificationResponse(response);
    } catch (e) {
      devPrint('❌ Error handling notification response: $e');
    }
  }

  /// Public testable method for handling notification responses
  /// Delegates to the handler's method - kept for backward compatibility with existing tests
  /// @visibleForTesting
  @visibleForTesting
  Future<void> handleNotificationResponseForTesting(NotificationResponse response) async {
    // Simply delegate to the handler
    await _handler.handleNotificationResponse(response);
  }

  Future<void> _createNotificationChannel() async {
    // Get the selected sound path
    final selectedSoundPath = await getSelectedSoundPath();

    // Create a notification channel for Android
    AndroidNotificationChannel channel;

    if (selectedSoundPath != null && selectedSoundPath.isNotEmpty) {
      // Use custom sound
      devPrint('Using custom notification sound: $selectedSoundPath');

      // For custom sounds, we need to use a RawResourceAndroidNotificationSound
      // The sound file should be in the raw resource folder
      // For asset sounds, we'll use the default sound for now
      // In a production app, you would copy the asset to the raw resource folder
      channel = const AndroidNotificationChannel(
        'pill_channel_id', // Channel ID
        'Pill Reminders', // Channel name
        description: 'Reminders for taking your pills',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: RawResourceAndroidNotificationSound(
            'pill_alarm'), // Use custom sound
      );
    } else {
      // Use default sound
      devPrint('Using default notification sound');
      channel = const AndroidNotificationChannel(
        'pill_channel_id', // Channel ID
        'Pill Reminders', // Channel name
        description: 'Reminders for taking your pills',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: null, // Use default sound
      );
    }

    // Create the channel
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    devPrint('Created notification channel');
  }

  // Show an immediate notification for testing
  Future<void> showImmediateNotification() async {
    final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000]);
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pill_channel_id',
      'Pill Reminders',
      channelDescription: 'Reminders for taking your pills',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'PILL_REMINDER_CATEGORY',
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification',
      platformChannelSpecifics,
      payload: 'test',
    );

    devPrint('Showed immediate notification');
  }

  // ============================================================================
  // NotificationScheduler interface implementation
  // ============================================================================
  
  /// Schedules a notification (implements NotificationScheduler interface)
  /// This is used by the NotificationResponseHandler for snooze functionality
  @override
  Future<void> scheduleNotification(
    int id,
    String title,
    String body, {
    Map<String, dynamic>? payload,
    bool includeSnoozeAction = true,
  }) async {
    // Delegate to showNotification
    await showNotification(id, title, body, payload: payload, includeSnoozeAction: includeSnoozeAction);
  }
  
  /// Cancels a notification (implements NotificationScheduler interface)
  /// This is used by the NotificationResponseHandler for mark-as-taken functionality
  @override
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
  
  // ============================================================================
  // Public notification methods
  // ============================================================================

  /// Show a notification with optional payload and snooze action
  Future<void> showNotification(
    int id,
    String title,
    String body, {
    Map<String, dynamic>? payload,
    bool includeSnoozeAction = true,
  }) async {
    // Get the selected sound
    final selectedSoundPath = await getSelectedSoundPath();
    
    // Create Android notification details with actions
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pill_channel_id',
      'Pill Reminders',
      channelDescription: 'Reminders for taking your pills',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(selectedSoundPath ?? 'pill_alarm'),
      // Include action buttons for the notification
      actions: includeSnoozeAction ? <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'SNOOZE_ACTION',
          'Snooze',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'MARK_TAKEN_ACTION',
          'Mark as Taken',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ] : null,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'PILL_REMINDER_CATEGORY',
    );
    
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Convert payload to string if provided
    final String? payloadStr = payload != null ? json.encode(payload) : null;
    
    // Show the notification
    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payloadStr,
    );
    
    devPrint('Showed notification with ID: $id, Title: $title, Payload: $payloadStr');
  }

  /// Schedule a pill reminder notification
  Future<void> schedulePillReminder(
    int id,
    String title,
    String body,
    DateTime scheduledTime, {
    Map<String, dynamic>? payload,
    bool includeSnoozeAction = true,
  }) async {
    // Get the selected sound
    final selectedSoundPath = await getSelectedSoundPath();
    devPrint('Using custom notification sound for reminder: $selectedSoundPath');

    // Create notification details
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pill_channel_id',
      'Pill Reminders',
      channelDescription: 'Reminders for taking your pills',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(selectedSoundPath ?? 'pill_alarm'),
      additionalFlags: Int32List.fromList(<int>[4]), // Insistent flag for Android
      // Add actions for the notification
      actions: includeSnoozeAction ? <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'SNOOZE_ACTION',
          'Snooze',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'MARK_TAKEN_ACTION',
          'Mark as Taken',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ] : null,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'PILL_REMINDER_CATEGORY',
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Ensure we include notificationId in the payload for action handling
    if (payload != null) {
      payload['notificationId'] = id.toString();
    }
    
    // Convert payload to string
    final String? payloadStr = payload != null ? json.encode(payload) : null;
    
    // Log full payload for debugging
    devPrint('Scheduling notification with payload: $payloadStr');

    // Convert to TZDateTime
    final tz.TZDateTime zonedTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Schedule the notification
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      zonedTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payloadStr,
    );

    devPrint('Scheduled pill reminder for $zonedTime');
  }

  /// Schedule a notification at a specific time using timezone
  Future<void> zonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    String? payload,
    required AndroidScheduleMode androidScheduleMode,
  }) async {
    try {
      // Try to schedule with exact timing first
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      devPrint('Scheduled notification for: $scheduledDate');
    } catch (e) {
      // If exact alarms are not permitted, fall back to inexact alarms
      if (e.toString().contains('exact_alarms_not_permitted')) {
        devPrint('Exact alarms not permitted, falling back to inexact alarms');

        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
        devPrint('Scheduled inexact notification for: $scheduledDate');
      } else {
        // For other errors, rethrow
        devPrint('Error scheduling notification: $e');
        rethrow;
      }
    }
  }

  // Cancel a specific reminder
  Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Cancel ALL scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    devPrint('🧹 Cancelled ALL scheduled notifications from the system');
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    // Android: use plugin-provided check
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }

    // iOS: rely on permission_handler status (robust and simple)
    if (Platform.isIOS) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }

    // Other platforms: default to false
    return false;
  }
}
