import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/push/fcm_token_store.dart';
import 'package:petdate/push/push_coordinator.dart';
import 'package:petdate/push/push_messaging.dart';
import 'package:petdate/push/push_prompt_store.dart';
import 'package:petdate/state/user_doc_provider.dart';

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

final pushPromptStoreProvider = Provider<PushPromptStore>((ref) {
  return PrefsPushPromptStore();
});

final pushMessagingProvider = Provider<PushMessaging>((ref) {
  return createDefaultPushMessaging();
});

final pushTokenStoreProvider = Provider<PushTokenStore>((ref) {
  return createDefaultPushTokenStore();
});

final pushCoordinatorProvider = Provider<PushCoordinator>((ref) {
  final coordinator = PushCoordinator(
    store: ref.watch(pushPromptStoreProvider),
    messaging: ref.watch(pushMessagingProvider),
    tokenStore: ref.watch(pushTokenStoreProvider),
    hasAuth: () => IdentityRemote.isLiveAuthReady,
    isVerified: () => ref.read(isVerifiedProvider),
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
