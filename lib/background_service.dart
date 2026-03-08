import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_usage/app_usage.dart';

// This is the entry point for the background service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );
}

// This is the main logic that runs in the background isolate.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  Timer? timer;
  Timer? appFocusTimer;
  bool isShowingNotification = false;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'focus_channel',
      'Focus Channel',
      channelDescription: 'Notifications for focus mode',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Stay Focused!',
      body: 'Return to your task to keep making progress.',
      notificationDetails: platformDetails,
    );
    isShowingNotification = true;
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(id: 0);
    isShowingNotification = false;
  }

  service.on('start').listen((event) async {
    // --- Safely handle incoming data ---
    if (event == null) return;
    final endTime = event['endTime'] as int? ?? 0;
    final packageName = event['packageName'] as String? ?? '';
    if (endTime == 0 || packageName.isEmpty) return;
    // ------------------------------------

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = (endTime - now) ~/ 1000;

      if (remaining > 0) {
        service.invoke('update', {'remaining': remaining});
      } else {
        service.invoke('stop');
        timer.cancel();
        appFocusTimer?.cancel();
        if (isShowingNotification) cancelNotification();
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final focusMode = prefs.getBool('focusMode') ?? false;

    if (focusMode && Platform.isAndroid) {
      appFocusTimer?.cancel();
      appFocusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          DateTime endDate = DateTime.now();
          DateTime startDate = endDate.subtract(const Duration(seconds: 10));
          List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);

          if (infoList.isNotEmpty) {
            final currentApp = infoList.first;
            if (currentApp.packageName != packageName) {
              if (!isShowingNotification) showNotification();
            } else {
              if (isShowingNotification) cancelNotification();
            }
          }
        } catch (e) {
          // Silently handle errors
        }
      });
    }
  });

  service.on('stop').listen((event) {
    timer?.cancel();
    appFocusTimer?.cancel();
    if (isShowingNotification) cancelNotification();
  });
}
