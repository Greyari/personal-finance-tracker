import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String channelId = 'finance_notes_reminders';
  static const String channelName = 'Pengingat Catatan Keuangan';
  static const String channelDescription =
      'Notifikasi pengingat catatan dan jadwal keuangan';

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      if (offset.inHours == 7) {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } else if (offset.inHours == 8) {
        tz.setLocalLocation(tz.getLocation('Asia/Makassar'));
      } else if (offset.inHours == 9) {
        tz.setLocalLocation(tz.getLocation('Asia/Jayapura'));
      } else {
        try {
          tz.setLocalLocation(tz.getLocation(now.timeZoneName));
        } catch (_) {
          tz.setLocalLocation(tz.local);
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Timezone init error: $e');
    }

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux settings
    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint(
              '[NotificationService] Notification tapped: ${details.payload}');
        },
      );

      // Create Android Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          const androidChannel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          );
          await androidImplementation
              .createNotificationChannel(androidChannel);
        }
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Ready (v18.0.1)');
    } catch (e) {
      debugPrint('[NotificationService] Initialize error: $e');
    }
  }

  /// Request notification permissions for Android 13+ and iOS
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await androidImpl?.requestNotificationsPermission() ?? false;
        return granted;
      } else if (Platform.isIOS) {
        final iosImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return granted;
      }
    } catch (e) {
      debugPrint('[NotificationService] requestPermissions error: $e');
    }
    return true;
  }

  NotificationDetails _getPlatformDetails() {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
  }

  /// Show an immediate notification (ideal for quick test or instant alert)
  Future<void> showInstantNotification({
    int id = 99999,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        _getPlatformDetails(),
        payload: payload,
      );
      debugPrint('[NotificationService] Instant notification shown: $title');
    } catch (e) {
      debugPrint('[NotificationService] showInstantNotification error: $e');
    }
  }

  /// Show an instant WhatsApp-like chat message notification
  Future<void> showChatNotification({
    required int id,
    required String senderName,
    required String messageText,
    String? chatId,
  }) async {
    await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'chat_messages_channel',
        'Pesan Obrolan',
        channelDescription: 'Notifikasi pesan obrolan baru dari pasangan',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _notificationsPlugin.show(
        id,
        senderName,
        messageText,
        const NotificationDetails(android: androidDetails, iOS: darwinDetails),
        payload: chatId,
      );
    } catch (e) {
      debugPrint('[NotificationService] showChatNotification error: $e');
    }
  }

  /// Schedule a reminder for a Sticky Note
  Future<void> scheduleNoteReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    DateTime? date,
    bool isDaily = false,
  }) async {
    await init();
    try {
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate;

      if (isDaily) {
        scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      } else {
        final targetDate = date ?? now;
        scheduledDate = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );
        if (scheduledDate.isBefore(now)) {
          scheduledDate = now.add(const Duration(seconds: 5));
        }
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _getPlatformDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            isDaily ? DateTimeComponents.time : null,
      );

      debugPrint(
          '[NotificationService] Scheduled notification ID $id at $scheduledDate (daily=$isDaily)');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling notification: $e');
      // Fallback with inexact alarm if exact alarm permission is restricted
      try {
        final now = tz.TZDateTime.now(tz.local);
        var fallbackDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        if (fallbackDate.isBefore(now)) {
          fallbackDate = fallbackDate.add(const Duration(days: 1));
        }
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          fallbackDate,
          _getPlatformDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents:
              isDaily ? DateTimeComponents.time : null,
        );
      } catch (err) {
        debugPrint('[NotificationService] Fallback schedule error: $err');
      }
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('[NotificationService] Cancelled notification ID $id');
    } catch (e) {
      debugPrint('[NotificationService] cancelNotification error: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[NotificationService] Cancelled all notifications');
    } catch (e) {
      debugPrint('[NotificationService] cancelAllNotifications error: $e');
    }
  }
}
