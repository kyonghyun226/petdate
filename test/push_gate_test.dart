import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/push/fcm_token_store.dart';
import 'package:petdate/push/push_payload.dart';
import 'package:petdate/push/push_permission_gate.dart';
import 'package:petdate/push/push_prompt_store.dart';

void main() {
  test('Auth 없으면 권한 게이트는 no-op', () {
    expect(IdentityRemote.isLiveAuthReady, isFalse);
    const gate = PushPermissionGate(
      hasAuth: false,
      isVerified: true,
      firstMatchSeen: true,
      alreadyAsked: false,
    );
    expect(gate.canShowPreprompt, isFalse);
    expect(gate.canRequestOsPermission, isFalse);
  });

  test('미인증(verifiedAt 없음)은 권한 요청 금지', () {
    const gate = PushPermissionGate(
      hasAuth: true,
      isVerified: false,
      firstMatchSeen: true,
      alreadyAsked: false,
    );
    expect(gate.canShowPreprompt, isFalse);
  });

  test('첫 매칭 전에는 온보딩·가입 직후라도 묻지 않음', () {
    const gate = PushPermissionGate(
      hasAuth: true,
      isVerified: true,
      firstMatchSeen: false,
      alreadyAsked: false,
    );
    expect(gate.canShowPreprompt, isFalse);
  });

  test('이미 물었으면 재요청 스팸 금지', () {
    const gate = PushPermissionGate(
      hasAuth: true,
      isVerified: true,
      firstMatchSeen: true,
      alreadyAsked: true,
    );
    expect(gate.canShowPreprompt, isFalse);
  });

  test('첫 매칭 + 인증 + Auth + 미요청일 때만 프리프롬프트', () {
    const gate = PushPermissionGate(
      hasAuth: true,
      isVerified: true,
      firstMatchSeen: true,
      alreadyAsked: false,
    );
    expect(gate.canShowPreprompt, isTrue);
    expect(gate.canRequestOsPermission, isTrue);
  });

  test('거절 뒤에만 Y01 알림 켜기', () {
    final store = InMemoryPushPromptStore();
    expect(store.shouldOfferEnableInSettings, isFalse);
    store.markDeclinedPreprompt();
    expect(store.shouldOfferEnableInSettings, isTrue);
    store.markGranted();
    expect(store.shouldOfferEnableInSettings, isFalse);
    store.markOsDenied();
    expect(store.shouldOfferEnableInSettings, isTrue);
  });

  test('payload parses type + threadId (matchId alias)', () {
    expect(
      PushPayload.tryParse({'type': 'match', 'threadId': 'aaa_bbb'}),
      isA<PushPayload>()
          .having((p) => p.type, 'type', PushKind.match)
          .having((p) => p.threadId, 'threadId', 'aaa_bbb'),
    );
    expect(
      PushPayload.tryParse({'type': 'meet_proposal', 'matchId': 'aaa_bbb'})
          ?.threadId,
      'aaa_bbb',
    );
    expect(PushPayload.tryParse({'type': 'message'}), isNull);
    expect(PushPayload.tryParse({}), isNull);
    expect(
      const PushPayload(type: PushKind.message, threadId: 'a_b').toData(),
      {'type': 'message', 'matchId': 'a_b'},
    );
  });

  test('token write map never includes verifiedAt; doc id is sha256', () {
    final map = FcmTokenFields.clientWriteMap(
      tokenValue: 'tok',
      platformValue: 'android',
      updatedAtValue: 'server',
    );
    expect(map.keys, ['token', 'platform', 'updatedAt']);
    expect(map.containsKey('verifiedAt'), isFalse);
    expect(
      FcmTokenFields.documentId('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    expect(FcmTokenFields.documentId('abc'), isNot('abc'));
  });

  test('push copy is pet-friend / walk, not dating', () {
    final bundle = [
      AppCopy.pushPrepromptTitle,
      AppCopy.pushPrepromptBody,
      AppCopy.pushPrepromptAllow,
      AppCopy.pushPrepromptDeny,
      AppCopy.settingsEnableNotifications,
      AppCopy.settingsNotificationsHint,
      AppCopy.pushMatchTitle,
      AppCopy.pushMatchBody,
      AppCopy.pushMessageTitle,
      AppCopy.pushMessageBody,
      AppCopy.pushMeetupTitle,
      AppCopy.pushMeetupBody,
    ].join(' ');
    expect(bundle, contains('반짝 소식 받으실래요?'));
    expect(bundle, isNot(contains('연애')));
    expect(bundle, isNot(contains('데이트')));
    expect(bundle, isNot(contains('썸')));
    expect(bundle, isNot(contains('설렘')));
    expect(bundle, isNot(contains('소개팅')));
  });
}
