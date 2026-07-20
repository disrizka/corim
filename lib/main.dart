import 'package:corim/auth/splash_screen.dart';
import 'package:corim/notifications/notification_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? _extractNotificationId(Map<String, dynamic> data) {
  debugPrint('[NOTIF DEBUG] raw data payload: $data');

  final id =
      data['notificationId']?.toString() ??
      data['notification_id']?.toString() ??
      data['id']?.toString();

  debugPrint('[NOTIF DEBUG] extracted id: $id');
  return id;
}

void _openNotificationDetail(String id) {
  debugPrint('[NOTIF DEBUG] _openNotificationDetail called with id=$id');
  final navigator = navigatorKey.currentState;
  if (navigator == null) {
    debugPrint('[NOTIF DEBUG] navigatorKey.currentState is NULL, batal push');
    return;
  }
  navigator.push(
    MaterialPageRoute(
      builder: (_) => NotificationDetailScreen(notificationId: id),
    ),
  );
  debugPrint('[NOTIF DEBUG] push berhasil dipanggil');
}

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
  playSound: true,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint(
          '[NOTIF DEBUG] onDidReceiveNotificationResponse, payload=${details.payload}',
        );
        final id = details.payload;
        if (id != null && id.isNotEmpty) {
          _openNotificationDetail(id);
        } else {
          debugPrint('[NOTIF DEBUG] payload kosong/null, tidak navigasi');
        }
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      '[NOTIF DEBUG] permission status: ${settings.authorizationStatus}',
    );

    String? fcmToken = await messaging.getToken();
    debugPrint("FCM TOKEN FLUTTER: $fcmToken");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[NOTIF DEBUG] onMessage diterima. notification=${message.notification?.title}, data=${message.data}',
      );

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        final notifId = _extractNotificationId(message.data);
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
            ),
          ),
          payload: notifId,
        );
        debugPrint(
          '[NOTIF DEBUG] local notification ditampilkan dengan payload=$notifId',
        );
      } else {
        debugPrint(
          '[NOTIF DEBUG] notification atau android null -> tidak ada local notif yang ditampilkan (kemungkinan data-only message)',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '[NOTIF DEBUG] onMessageOpenedApp diterima. data=${message.data}',
      );
      final id = _extractNotificationId(message.data);
      if (id != null && id.isNotEmpty) {
        _openNotificationDetail(id);
      } else {
        debugPrint('[NOTIF DEBUG] id null/kosong dari onMessageOpenedApp');
      }
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    debugPrint('[NOTIF DEBUG] getInitialMessage: ${initialMessage?.data}');
    if (initialMessage != null) {
      final id = _extractNotificationId(initialMessage.data);
      if (id != null && id.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 800), () {
            _openNotificationDetail(id);
          });
        });
      } else {
        debugPrint('[NOTIF DEBUG] id null/kosong dari getInitialMessage');
      }
    }
  } catch (e, st) {
    debugPrint("Firebase initialization failed: $e");
    debugPrint("$st");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Corim Apex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 36, 199),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
