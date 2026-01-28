import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotiService {
  // Singleton pattern
  NotiService._();
  static final NotiService instance = NotiService._();

  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool get isInitialized => _isInitialized;
  bool get isPermissionGranted => _isPermissionGranted;
  bool get hasRequestedPermission => _hasRequestedPermission;

  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  bool _hasRequestedPermission = false;

  /// Initialize notifications and request permission once at app launch.
  /// This should be called once from main.dart when app starts.
  Future<void> initNotification() async {
    if (_isInitialized) {
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings("@mipmap/launcher_icon");

    const initSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    _isInitialized = true;

    // Request notification permission once at initialization
    await requestNotificationPermission();
  }

  /// Request notification permission once. Should only be called at app start.
  /// Subsequent calls will return the cached result without showing a popup.
  Future<bool> requestNotificationPermission() async {
    // If already requested, return the cached result
    if (_hasRequestedPermission) {
      return _isPermissionGranted;
    }

    // Mark as requested before making the request
    _hasRequestedPermission = true;

    // Only Android 13+ requires runtime notification permission
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      _isPermissionGranted = status.isGranted;
    } else {
      // For other platforms, assume granted or handle separately
      _isPermissionGranted = true;
    }

    return _isPermissionGranted;
  }

  /// Check if notification permission is granted without requesting it.
  /// Returns the cached value if already checked, otherwise checks the current status.
  Future<bool> checkNotificationPermission() async {
    // If we already requested permission, return the cached result
    if (_hasRequestedPermission) {
      return _isPermissionGranted;
    }

    // Otherwise, just check the status without requesting
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      _isPermissionGranted = status.isGranted;
      return _isPermissionGranted;
    }
    return true;
  }

  // Handle notification tap when app is in foreground
  static void _onNotificationTap(NotificationResponse response) {
    _handleNotificationPayload(response.payload);
  }

  // Handle notification tap when app is in background or closed
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    _handleNotificationPayload(response.payload);
  }

  // Process the notification payload
  static void _handleNotificationPayload(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      // Handle the payload here (e.g., navigate to a specific screen)
    }
  }

  NotificationDetails notiDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'depass_channel',
        'Depass Notifications',
        channelDescription: 'Notifications for Depass app',
        importance: Importance.max,
        priority: Priority.high,
        playSound: false,
      ),
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }

    // Check if permission is granted before showing notification
    if (!_isPermissionGranted) {
      // Re-check permission status in case it was granted via settings
      await checkNotificationPermission();
      if (!_isPermissionGranted) {
        // Permission still not granted, can't show notification
        debugPrint(
          'NotiService: Cannot show notification - permission not granted',
        );
        return;
      }
    }

    debugPrint('NotiService: Showing notification - id: $id, title: $title');
    await notificationsPlugin.show(id, title, body, notiDetails());
  }
}
