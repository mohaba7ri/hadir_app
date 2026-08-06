import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';
import 'auth_controller.dart';
import '../core/utils/ui_utils.dart';

class NotificationController extends GetxController
    with WidgetsBindingObserver {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = Get.find<ApiService>();

  // THE CURRENT VERSION OF THE APP (Increment this for every new release)
  final int currentAppVersion = 10;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
    checkVersionOnLaunch();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-verify update status every time they come back to the app
      checkVersionOnLaunch();
    }
  }

  /// Checks the backend settings to see if an update is mandatory.
  /// This ensures that even users who missed the push notification
  /// are blocked until they update.
  Future<void> checkVersionOnLaunch() async {
    try {
      final auth = Get.find<AuthController>();
      // EXCLUDE ADMINS FROM FORCED UPDATE
      if (auth.isAdmin.value) return;

      final data = await _api.getData('settings');
      if (data != null) {
        final settings = SettingsModel.fromJson(data);
        if (settings.minVersion > currentAppVersion &&
            settings.forceUpdateUrl != null) {
          print(
              'Mandatory update required! Min: ${settings.minVersion}, App: $currentAppVersion');
          showForceUpdateDialog(settings.forceUpdateUrl!);
        }
      }
    } catch (e) {
      print('Error checking version: $e');
    }
  }

  Future<void> _initNotifications() async {
    try {
      print('Initializing notifications context...');
      // 1. Request Permission (Mobile & Web)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      }

      // 2. Initial Setup for Local Notifications (Foreground - No-op on Web usually)
      if (!kIsWeb) {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings =
            InitializationSettings(android: initializationSettingsAndroid);
        await _localNotifications.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (details) {
            print('Notification tapped: ${details.payload}');
          },
        );
      }

      // 3. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a notification whilst in the foreground!');
        print('Data payload: ${message.data}');

        // CHECK FOR FORCE UPDATE FIRST
        _checkForForceUpdate(message);

        String? title = message.notification?.title;
        String? body = message.notification?.body;

        // If notification object is missing (data-only message), try data payload
        if (title == null && message.data.containsKey('title')) {
          title = message.data['title'];
        }
        if (body == null && message.data.containsKey('body')) {
          body = message.data['body'];
        }

        if (title != null || body != null) {
          showLocalNotification(
            title ?? 'تنبيه جديد',
            body ?? '',
          );
        }
      });

      // 4. Handle Background/Terminated Click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        _checkForForceUpdate(message);
      });

      // 5. Subscribe to All Users (For system broadcasts like force updates)
      if (!kIsWeb) {
        await _fcm.subscribeToTopic('all_users');
        print('Subscribed to all_users topic');
      }

      // 6. Get Token
      String? token = await _fcm.getToken();
      print("FCM Token: $token");

      // Handle Initial Message (App launched from terminated state via notification)
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _checkForForceUpdate(initialMessage);
      }
    } catch (e) {
      print('Error in _initNotifications: $e');
    }
  }

  void _checkForForceUpdate(RemoteMessage message) {
    // EXCLUDE ADMINS
    final auth = Get.find<AuthController>();
    if (auth.isAdmin.value) return;

    // Check data payload for force_update_url
    final updateUrl = message.data['force_update_url'];
    if (updateUrl != null && updateUrl.toString().isNotEmpty) {
      showForceUpdateDialog(updateUrl.toString());
    }
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }

  Future<void> subscribeToAdmin() async {
    if (kIsWeb) {
      print(
          'FCM Web: Client-side subscription skipped (use backend with registration token).');
      return;
    }
    try {
      await _fcm.subscribeToTopic('admin_notifications');
      print('Subscribed to admin topic');
    } catch (e) {
      print('FCM Subscribe error: $e');
    }
  }

  Future<void> subscribeToEmployee(int? id) async {
    if (id == null) return;
    if (kIsWeb) {
      print('FCM Web: Client-side subscription skipped (use backend).');
      return;
    }
    try {
      await _fcm.subscribeToTopic('employee_$id');
      print('Subscribed to employee topic for ID: $id');
    } catch (e) {
      print('FCM Subscribe error: $e');
    }
  }

  void showForceUpdateDialog(String url) {
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      PopScope(
        canPop: false, // Prevent back button
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 48, color: Colors.blue),
              ),
              SizedBox(height: 20),
              const Text(
                'تحديث جديد لتطبيق حاضر',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'يسرنا إبلاغك بتوفر نسخة جديدة ومطورة من تطبيق حاضر. لضمان استمتاعك بأفضل تجربة وأقصى استقرار للنظام، يرجى تحديث التطبيق الآن.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(height: 1.6, fontSize: 13, color: Colors.black87),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  _launchUrl(url);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('تحديث الآن',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false, // Prevent clicking outside
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      print('Could not launch $url');
    }
  }

  // Task: Trigger a local notification or snackbar for feedback
  Future<void> showLocalNotification(String title, String body) async {
    if (kDebugMode) {
      print('Debug Mode: Blocked showing local notification: $title');
      return;
    }
    print('Showing notification: $title - $body');
    if (kIsWeb) {
      UiUtils.showSuccessDialog(title, body);
      return;
    }

    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'notification_system',
      'System Notifications',
      channelDescription: 'Used for status updates and alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: android),
    );
  }
}
