import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/push/fcm_token_store.dart';
import 'package:petdate/push/push_messaging.dart';
import 'package:petdate/push/push_payload.dart';
import 'package:petdate/push/push_permission_gate.dart';
import 'package:petdate/push/push_preprompt.dart';
import 'package:petdate/push/push_prompt_store.dart';

typedef PushAuthCheck = bool Function();

/// Permission timing, token sync, and tap → C02. Auth missing is a no-op.
class PushCoordinator {
  PushCoordinator({
    required this.store,
    required this.messaging,
    required this.tokenStore,
    required this.hasAuth,
    required this.isVerified,
    this.navigatorKey,
    this.platformOverride,
  });

  final PushPromptStore store;
  final PushMessaging messaging;
  final PushTokenStore tokenStore;
  final PushAuthCheck hasAuth;
  final PushAuthCheck isVerified;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? platformOverride;

  StreamSubscription<Map<String, dynamic>>? _openedSub;
  String? _lastToken;
  bool _attached = false;

  PushPermissionGate gate() => PushPermissionGate(
    hasAuth: hasAuth(),
    isVerified: isVerified(),
    firstMatchSeen: store.firstMatchSeen,
    alreadyAsked: store.hasAsked,
  );

  bool get shouldOfferEnableInSettings => store.shouldOfferEnableInSettings;

  Future<void> attach() async {
    if (_attached) return;
    _attached = true;
    await store.hydrate();
    await _listenOpened();
    await syncTokenIfAllowed();
  }

  Future<void> _listenOpened() async {
    if (!hasAuth()) return;
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      openFromData(initial);
    }
    await _openedSub?.cancel();
    _openedSub = messaging.onOpened.listen(openFromData);
  }

  /// First M01 match only. Pre-prompt → OS. Deny never blocks M01/C02.
  Future<void> onFirstMatchSuccess(BuildContext context) async {
    await store.markFirstMatchSeen();
    if (!gate().canShowPreprompt) return;
    if (!context.mounted) return;

    final allow = await showPushPreprompt(context);
    if (allow) {
      await store.markAsked();
      final granted = await messaging.requestPermission();
      if (granted) {
        await store.markGranted();
        await syncTokenIfAllowed();
      } else {
        await store.markOsDenied();
      }
    } else {
      await store.markDeclinedPreprompt();
    }
  }

  Future<void> syncTokenIfAllowed() async {
    if (!hasAuth() || !isVerified()) return;
    final authorized = await messaging.isAuthorized();
    if (!authorized) return;
    await store.markGranted();
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;
    _lastToken = token;
    await tokenStore.upsert(token: token, platform: _platform());
  }

  Future<void> openOsNotificationSettings() async {
    await messaging.openAppNotificationSettings();
  }

  /// OS notification permission currently authorized.
  Future<bool> isEnabled() async {
    try {
      return await messaging.isAuthorized();
    } on Object {
      return false;
    }
  }

  /// Settings toggle ON: request OS permission and sync token.
  Future<bool> enableFromSettings() async {
    await store.markAsked();
    final granted = await messaging.requestPermission();
    if (granted) {
      await store.markGranted();
      await syncTokenIfAllowed();
      return true;
    }
    await store.markOsDenied();
    await openOsNotificationSettings();
    return false;
  }

  /// Settings toggle OFF: drop token and open OS settings to revoke.
  Future<void> disableFromSettings() async {
    final token = _lastToken;
    _lastToken = null;
    if (token != null) {
      await tokenStore.clear(token: token);
    }
    await tokenStore.clearAllForCurrentUser();
    await store.markDeclinedPreprompt();
    await openOsNotificationSettings();
  }

  Future<void> onSignedOut() async {
    final token = _lastToken;
    _lastToken = null;
    if (token != null) {
      await tokenStore.clear(token: token);
    }
    await tokenStore.clearAllForCurrentUser();
    await _openedSub?.cancel();
    _openedSub = null;
    _attached = false;
  }

  void openFromData(Map<String, dynamic> data) {
    final payload = PushPayload.tryParse(data);
    if (payload == null) return;
    final context = navigatorKey?.currentContext;
    if (context == null || !context.mounted) return;
    unawaited(openChatRoomById(context, payload.threadId));
  }

  String _platform() {
    if (platformOverride != null) return platformOverride!;
    try {
      if (Platform.isIOS) return 'ios';
    } on Object {
      // Tests / unexpected hosts.
    }
    return 'android';
  }

  Future<void> dispose() async {
    await _openedSub?.cancel();
    _openedSub = null;
  }
}
