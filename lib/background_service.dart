import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_usage/app_usage.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'focus_channel', // id
    'Focus Channel', // title
    description: 'Notifications for focus mode', // description
    importance: Importance.max, // importance
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: 'focus_channel',
      initialNotificationTitle: 'Focus Mode',
      initialNotificationContent: 'Task in progress...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? timer;

  service.on('start').listen((event) async {
    timer?.cancel();
    if (event == null) return;
    final endTime = event['endTime'] as int? ?? 0;
    final packageName = event['packageName'] as String? ?? '';
    if (endTime == 0) return;

    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = (endTime - now) ~/ 1000;

      if (remaining > 0) {
        service.invoke('update', {'remaining': remaining});

        if (packageName.isNotEmpty && Platform.isAndroid) {
          try {
            List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
                DateTime.now().subtract(const Duration(seconds: 10)),
                DateTime.now());
            if (infoList.isNotEmpty &&
                infoList.first.packageName != packageName) {
              flutterLocalNotificationsPlugin.show(
                0,
                'Stay Focused!',
                'Return to your task to keep making progress.',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'focus_channel',
                    'Focus Channel',
                    channelDescription: 'Notifications for focus mode',
                    importance: Importance.max,
                    priority: Priority.high,
                    ongoing: true,
                    autoCancel: false,
                  ),
                ),
              );
            } else {
              flutterLocalNotificationsPlugin.cancel(0);
            }
          } catch (e) {
            // silent error
          }
        }
      } else {
        service.invoke('stop');
        timer.cancel();
        flutterLocalNotificationsPlugin.cancel(0);
      }
    });
  });

  service.on('stop').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });
}
