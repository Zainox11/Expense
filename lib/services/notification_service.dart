import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Service responsible for managing local notifications throughout the app.
///
/// Handles budget alerts, recurring transaction reminders, and scheduled
/// notifications with proper platform-specific configuration for Android & iOS.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channel constants
  static const String _budgetChannelId = 'budget_alerts';
  static const String _budgetChannelName = 'Budget Alerts';
  static const String _budgetChannelDesc =
      'Notifications when your spending approaches or exceeds budget limits';

  static const String _recurringChannelId = 'recurring_reminders';
  static const String _recurringChannelName = 'Recurring Reminders';
  static const String _recurringChannelDesc =
      'Reminders for recurring transactions that are due';

  static const String _generalChannelId = 'general';
  static const String _generalChannelName = 'General';
  static const String _generalChannelDesc = 'General app notifications';

  // Fixed notification ID offsets to avoid collisions
  static const int _budgetWarningIdOffset = 10000;
  static const int _budgetExceededIdOffset = 20000;
  static const int _recurringReminderIdOffset = 30000;

  /// Initialize the notification service with platform-specific settings.
  ///
  /// Must be called once during app startup before using any other methods.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data for scheduled notifications
    tz_data.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS / macOS initialization settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  /// Create dedicated Android notification channels for different alert types.
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _budgetChannelId,
          _budgetChannelName,
          description: _budgetChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _recurringChannelId,
          _recurringChannelName,
          description: _recurringChannelDesc,
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _generalChannelId,
          _generalChannelName,
          description: _generalChannelDesc,
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  /// Handle notification tap events.
  ///
  /// Routes to the appropriate screen based on the notification payload.
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('NotificationService: Notification tapped with payload=$payload');

    if (payload == null || payload.isEmpty) return;

    // Payload format: "type:data"
    // e.g. "budget:Food" or "recurring:tx_123"
    final parts = payload.split(':');
    if (parts.length < 2) return;

    final type = parts[0];
    final data = parts.sublist(1).join(':');

    switch (type) {
      case 'budget':
        debugPrint(
          'NotificationService: Navigate to budget details for "$data"',
        );
        // Navigation is handled at the app level by listening to streams
        // or by using a global navigator key. The payload is parsed here
        // and can be consumed by a stream controller if needed.
        break;
      case 'recurring':
        debugPrint(
          'NotificationService: Navigate to transaction details for "$data"',
        );
        break;
      default:
        debugPrint('NotificationService: Unknown payload type "$type"');
    }
  }

  // ---------------------------------------------------------------------------
  // Budget Alert Notifications
  // ---------------------------------------------------------------------------

  /// Show a budget alert notification when spending approaches or exceeds limit.
  ///
  /// - At 80%+ usage: shows a warning notification.
  /// - At 100%+ usage: shows a critical exceeded notification.
  ///
  /// [categoryName] is the display name of the budget category.
  /// [percentUsed] is the current budget utilization as a percentage (0-∞).
  Future<void> showBudgetAlert({
    required String categoryName,
    required double percentUsed,
  }) async {
    _ensureInitialized();

    if (percentUsed < 80) return; // No alert needed below 80%

    final int roundedPercent = percentUsed.round();

    if (percentUsed >= 100) {
      // Budget exceeded — critical alert
      await _plugin.show(
        _budgetExceededIdOffset + categoryName.hashCode.abs() % 10000,
        '🚨 Budget Exceeded!',
        'You\'ve spent $roundedPercent% of your $categoryName budget. '
            'Consider reviewing your expenses.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _budgetChannelId,
            _budgetChannelName,
            channelDescription: _budgetChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFFE53935), // Red accent
            styleInformation: BigTextStyleInformation(
              'You\'ve used $roundedPercent% of your $categoryName budget. '
              'Time to slow down on spending in this category!',
              contentTitle: '🚨 Budget Exceeded — $categoryName',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'budget:$categoryName',
      );
    } else {
      // Budget warning — approaching limit (80-99%)
      await _plugin.show(
        _budgetWarningIdOffset + categoryName.hashCode.abs() % 10000,
        '⚠️ Budget Warning',
        'You\'ve used $roundedPercent% of your $categoryName budget.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _budgetChannelId,
            _budgetChannelName,
            channelDescription: _budgetChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFFFFA726), // Orange accent
            styleInformation: BigTextStyleInformation(
              'You\'ve used $roundedPercent% of your $categoryName budget. '
              'Be mindful of your spending to stay within limits.',
              contentTitle: '⚠️ Budget Warning — $categoryName',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'budget:$categoryName',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Recurring Transaction Reminders
  // ---------------------------------------------------------------------------

  /// Show a reminder for a recurring transaction that is due today.
  ///
  /// [transactionName] is a descriptive label (typically the note or category).
  /// [amount] is the transaction amount to display.
  Future<void> showRecurringReminder({
    required String transactionName,
    required double amount,
  }) async {
    _ensureInitialized();

    final formattedAmount = amount.toStringAsFixed(2);

    await _plugin.show(
      _recurringReminderIdOffset +
          transactionName.hashCode.abs() % 10000,
      '🔁 Recurring Transaction Due',
      '$transactionName — \$$formattedAmount is due today.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _recurringChannelId,
          _recurringChannelName,
          channelDescription: _recurringChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFF42A5F5), // Blue accent
          styleInformation: BigTextStyleInformation(
            'Your recurring transaction "$transactionName" of '
            '\$$formattedAmount is due today. Tap to view details.',
            contentTitle: '🔁 Recurring — $transactionName',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'recurring:$transactionName',
    );
  }

  // ---------------------------------------------------------------------------
  // Scheduled Notifications
  // ---------------------------------------------------------------------------

  /// Schedule a notification to be shown at a specific future date/time.
  ///
  /// Uses timezone-aware scheduling for accuracy across DST changes.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    _ensureInitialized();

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Only schedule if the date is in the future
    if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint(
        'NotificationService: Skipping past-date notification (id=$id)',
      );
      return;
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _generalChannelId,
          _generalChannelName,
          channelDescription: _generalChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null, // One-shot, not repeating
      payload: payload,
    );

    debugPrint(
      'NotificationService: Scheduled notification id=$id at $tzScheduledDate',
    );
  }

  /// Show an immediate general notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    _ensureInitialized();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _generalChannelId,
          _generalChannelName,
          channelDescription: _generalChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFF7A5CFF), // Accent purple
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------------
  // Cancellation
  // ---------------------------------------------------------------------------

  /// Cancel a specific notification by its unique [id].
  Future<void> cancelNotification(int id) async {
    _ensureInitialized();
    await _plugin.cancel(id);
    debugPrint('NotificationService: Cancelled notification id=$id');
  }

  /// Cancel all pending and displayed notifications.
  Future<void> cancelAll() async {
    _ensureInitialized();
    await _plugin.cancelAll();
    debugPrint('NotificationService: Cancelled all notifications');
  }

  // ---------------------------------------------------------------------------
  // Permission Requests
  // ---------------------------------------------------------------------------

  /// Request notification permissions on platforms that require explicit consent.
  ///
  /// Returns `true` if permission was granted, `false` otherwise.
  Future<bool> requestPermissions() async {
    // Android 13+ (API 33) requires runtime permission
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS requests are handled during initialization via DarwinInitializationSettings
    return true;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Throws if the service has not been initialized yet.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'NotificationService must be initialized before use. '
        'Call NotificationService().initialize() during app startup.',
      );
    }
  }
}

