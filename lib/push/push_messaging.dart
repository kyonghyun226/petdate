import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Permission + token + opened-message surface. Tests inject a fake.
abstract class PushMessaging {
  Future<bool> requestPermission();
  Future<bool> isAuthorized();
  Future<String?> getToken();
  Future<Map<String, dynamic>?> getInitialMessage();
  Stream<Map<String, dynamic>> get onOpened;
  Future<void> openAppNotificationSettings();
}

class NoopPushMessaging implements PushMessaging {
  const NoopPushMessaging();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> isAuthorized() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => null;

  @override
  Stream<Map<String, dynamic>> get onOpened => const Stream.empty();

  @override
  Future<void> openAppNotificationSettings() async {}
}

class RecordingPushMessaging implements PushMessaging {
  RecordingPushMessaging({
    this.authorized = false,
    this.grantOnRequest = false,
    this.token,
    this.initialMessage,
  });

  bool authorized;
  bool grantOnRequest;
  String? token;
  Map<String, dynamic>? initialMessage;

  int requestCount = 0;
  int tokenReads = 0;
  int openSettingsCount = 0;

  final _opened = StreamController<Map<String, dynamic>>.broadcast();

  void emitOpened(Map<String, dynamic> data) => _opened.add(data);

  @override
  Future<bool> requestPermission() async {
    requestCount += 1;
    authorized = grantOnRequest;
    return authorized;
  }

  @override
  Future<bool> isAuthorized() async => authorized;

  @override
  Future<String?> getToken() async {
    tokenReads += 1;
    if (!authorized) return null;
    return token;
  }

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => initialMessage;

  @override
  Stream<Map<String, dynamic>> get onOpened => _opened.stream;

  @override
  Future<void> openAppNotificationSettings() async {
    openSettingsCount += 1;
  }

  void dispose() => _opened.close();
}

class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return _isAuthorized(settings.authorizationStatus);
  }

  @override
  Future<bool> isAuthorized() async {
    final settings = await _messaging.getNotificationSettings();
    return _isAuthorized(settings.authorizationStatus);
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message?.data;
  }

  @override
  Stream<Map<String, dynamic>> get onOpened =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => m.data);

  @override
  Future<void> openAppNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  static bool _isAuthorized(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }
}

bool firebaseAppsReady() {
  try {
    return Firebase.apps.isNotEmpty;
  } on Object {
    return false;
  }
}

PushMessaging createDefaultPushMessaging() {
  if (!firebaseAppsReady()) return const NoopPushMessaging();
  try {
    return FirebasePushMessaging();
  } on Object catch (e) {
    assert(() {
      debugPrint('PushMessaging unavailable: $e');
      return true;
    }());
    return const NoopPushMessaging();
  }
}

/// OS shows the tray for notification payloads. Data-only is a no-op here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage _) async {}
