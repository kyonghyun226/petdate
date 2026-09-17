import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/app.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/firebase/firestore_ids.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/push/fcm_token_store.dart';
import 'package:petdate/push/push_coordinator.dart';
import 'package:petdate/push/push_messaging.dart';
import 'package:petdate/push/push_payload.dart';
import 'package:petdate/push/push_preprompt.dart';
import 'package:petdate/push/push_prompt_store.dart';
import 'package:petdate/push/push_providers.dart';
import 'package:petdate/screens/m01_match/m01_match_screen.dart';
import 'package:petdate/screens/y01_settings/y01_settings_screen.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/data/demo_mode.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

class _Harness {
  _Harness({
    bool verified = true,
    bool hasAuth = true,
    InMemoryPushPromptStore? store,
    RecordingPushMessaging? messaging,
  }) : store = store ?? InMemoryPushPromptStore(),
       messaging = messaging ?? RecordingPushMessaging(),
       tokens = RecordingPushTokenStore(),
       navKey = GlobalKey<NavigatorState>() {
    DemoMode.disableForTests();
    container = ProviderContainer(
      overrides: [
        ...testOverrides(
          auth: FakeAuthRepository(
            signedInUser: const AuthUser(
              uid: 'mock_uid',
              providerId: 'google.com',
            ),
          ),
        ),
        pushPromptStoreProvider.overrideWith((ref) => this.store),
        pushMessagingProvider.overrideWith((ref) => this.messaging),
        pushTokenStoreProvider.overrideWith((ref) => tokens),
        rootNavigatorKeyProvider.overrideWith((ref) => navKey),
        pushCoordinatorProvider.overrideWith((ref) {
          return PushCoordinator(
            store: this.store,
            messaging: this.messaging,
            tokenStore: tokens,
            hasAuth: () => hasAuth,
            isVerified: () => ref.read(isVerifiedProvider),
            navigatorKey: navKey,
            platformOverride: 'android',
          );
        }),
      ],
    );
    final session = container.read(sessionProvider.notifier);
    session.completeSplash();
    session.completeOnboarding();
    session.completeLogin();
    session.completeProfile();
    if (verified) {
      container
          .read(userDocProvider.notifier)
          .ingestListenSnapshot(verifiedAt: DateTime.utc(2026, 9, 8));
    }
  }

  final InMemoryPushPromptStore store;
  final RecordingPushMessaging messaging;
  final RecordingPushTokenStore tokens;
  final GlobalKey<NavigatorState> navKey;
  late final ProviderContainer container;

  void dispose() {
    container.dispose();
    messaging.dispose();
  }
}

Future<void> _pumpMain(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PetdateApp()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('온보딩·로그인에서 푸시 프리프롬프트/OS 권한을 요청하지 않음', (tester) async {
    DemoMode.disableForTests();
    final messaging = RecordingPushMessaging();
    final store = InMemoryPushPromptStore();
    final tokens = RecordingPushTokenStore();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((ref) => FakeAuthRepository()),
        pushPromptStoreProvider.overrideWith((ref) => store),
        pushMessagingProvider.overrideWith((ref) => messaging),
        pushTokenStoreProvider.overrideWith((ref) => tokens),
        pushCoordinatorProvider.overrideWith((ref) {
          return PushCoordinator(
            store: store,
            messaging: messaging,
            tokenStore: tokens,
            hasAuth: () => true,
            isVerified: () => true,
            platformOverride: 'android',
          );
        }),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(messaging.dispose);

    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PetdateApp(),
      ),
    );
    await pumpPastSplash(tester);

    expect(find.text(AppCopy.onboardingPages[0].title), findsOneWidget);
    expect(find.text(AppCopy.pushPrepromptTitle), findsNothing);
    expect(messaging.requestCount, 0);

    await tester.tap(find.text(AppCopy.alreadyHaveAccount));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.loginTitle), findsOneWidget);
    expect(find.text(AppCopy.pushPrepromptTitle), findsNothing);
    expect(messaging.requestCount, 0);
    expect(tokens.writes, isEmpty);
  });

  testWidgets('첫 M01 직후 프리프롬프트, 거절은 비블로킹이고 OS 요청 없음', (tester) async {
    final h = _Harness();
    addTearDown(h.dispose);
    await _pumpMain(tester, h.container);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.matchTitle), findsOneWidget);
    expect(find.text(AppCopy.pushPrepromptTitle), findsOneWidget);
    expect(h.messaging.requestCount, 0);

    await tester.tap(find.byKey(pushPrepromptDenyKey));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.pushPrepromptTitle), findsNothing);
    expect(find.text(AppCopy.matchTitle), findsOneWidget);
    expect(h.messaging.requestCount, 0);
    expect(h.store.declinedPreprompt, isTrue);
    expect(h.store.hasAsked, isTrue);

    await tester.tap(find.text(AppCopy.startChat));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.chatSystemMatch), findsOneWidget);
    expect(h.tokens.writes, isEmpty);
  });

  testWidgets('프리프롬프트 허용 후 OS 거절도 채팅을 막지 않음', (tester) async {
    final h = _Harness(
      messaging: RecordingPushMessaging(grantOnRequest: false),
    );
    addTearDown(h.dispose);
    await _pumpMain(tester, h.container);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pushPrepromptAllowKey));
    await tester.pumpAndSettle();

    expect(h.messaging.requestCount, 1);
    expect(h.store.osDenied, isTrue);
    expect(find.text(AppCopy.matchTitle), findsOneWidget);

    await tester.tap(find.text(AppCopy.later));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.homeTitle), findsOneWidget);
  });

  testWidgets('허용 후 토큰은 인증된 사용자만 저장', (tester) async {
    final h = _Harness(
      messaging: RecordingPushMessaging(
        grantOnRequest: true,
        token: 'fcm-test-token',
      ),
    );
    addTearDown(h.dispose);
    await _pumpMain(tester, h.container);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pushPrepromptAllowKey));
    await tester.pumpAndSettle();

    expect(h.messaging.requestCount, 1);
    expect(h.tokens.writes, [
      {'token': 'fcm-test-token', 'platform': 'android'},
    ]);
  });

  testWidgets('같은 세션에서 프리프롬프트를 다시 띄우지 않음', (tester) async {
    final h = _Harness();
    addTearDown(h.dispose);
    await _pumpMain(tester, h.container);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pushPrepromptDenyKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.later));
    await tester.pumpAndSettle();

    final ctx = h.navKey.currentContext!;
    await h.container.read(pushCoordinatorProvider).onFirstMatchSuccess(ctx);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.pushPrepromptTitle), findsNothing);
    expect(h.messaging.requestCount, 0);
  });

  testWidgets('푸시 탭 딥링크는 C02 스레드로 이동', (tester) async {
    expect(IdentityRemote.isLiveAuthReady, isFalse);
    final h = _Harness();
    addTearDown(h.dispose);
    await _pumpMain(tester, h.container);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pushPrepromptDenyKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.later));
    await tester.pumpAndSettle();

    final threadId = FirestoreIds.matchId('mock_uid', 'kong');
    final payload = PushPayload(type: PushKind.message, threadId: threadId);
    h.container.read(pushCoordinatorProvider).openFromData(payload.toData());
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.chatSystemMatch), findsOneWidget);
    expect(find.byType(M01MatchScreen), findsNothing);
  });

  testWidgets('권한 거절 후 Y01 알림 토글이 앱 설정으로 연결', (tester) async {
    final h = _Harness(
      store: InMemoryPushPromptStore(hasAsked: true, declinedPreprompt: true),
    );
    addTearDown(h.dispose);
    await _pumpMain(tester, h.container);

    await tester.tap(find.byKey(const ValueKey('profile-app-bar-button')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.mySettings));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.settingsNotifications), findsOneWidget);
    final tile = find.byKey(settingsEnableNotificationsKey);
    expect(tile, findsOneWidget);
    // Toggle ON when currently off → request / open settings path.
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(
      h.messaging.requestCount + h.messaging.openSettingsCount,
      greaterThan(0),
    );
  });

  testWidgets('Y01에 알림·위치 토글이 항상 보인다', (tester) async {
    final h = _Harness();
    addTearDown(h.dispose);
    await _pumpMain(tester, h.container);

    await tester.tap(find.byKey(const ValueKey('profile-app-bar-button')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.mySettings));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.settingsNotifications), findsOneWidget);
    expect(find.text(AppCopy.settingsLocation), findsOneWidget);
    expect(find.text(AppCopy.settingsRadius), findsNothing);
  });

  testWidgets('미인증이면 M01을 열어도 권한을 요청하지 않음', (tester) async {
    final h = _Harness(verified: false);
    addTearDown(h.dispose);

    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final kong = MockCatalog.byId('kong')!;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          home: M01MatchScreen(profile: kong, threadId: 'mock_uid_kong'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.matchTitle), findsOneWidget);
    expect(find.text(AppCopy.pushPrepromptTitle), findsNothing);
    expect(h.messaging.requestCount, 0);

    await h.container.read(pushCoordinatorProvider).syncTokenIfAllowed();
    expect(h.tokens.writes, isEmpty);
  });

  testWidgets('Auth 없으면 첫 매칭 콜백도 no-op', (tester) async {
    final h = _Harness(hasAuth: false);
    addTearDown(h.dispose);
    await _pumpMain(tester, h.container);

    await tester.tap(find.byKey(const ValueKey('like-button')));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.matchTitle), findsOneWidget);
    expect(find.text(AppCopy.pushPrepromptTitle), findsNothing);
    expect(h.messaging.requestCount, 0);
    expect(h.tokens.writes, isEmpty);
  });
}
