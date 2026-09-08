import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/data/backend_mode.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/data/mock_social_repository.dart';
import 'package:petdate/firebase/firestore_ids.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/firebase/pet_codec.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/profile_provider.dart';

void main() {
  test('like and match ids follow the official schema', () {
    const a = 'aaaaaaaaaaaaaaaa';
    const b = 'bbbbbbbbbbbbbbbb';
    expect(
      FirestoreIds.likeId(fromUid: a, toPetId: b),
      'aaaaaaaaaaaaaaaa_bbbbbbbbbbbbbbbb',
    );
    expect(FirestoreIds.matchId(a, b), 'aaaaaaaaaaaaaaaa_bbbbbbbbbbbbbbbb');
    expect(FirestoreIds.matchId(b, a), 'aaaaaaaaaaaaaaaa_bbbbbbbbbbbbbbbb');
    expect(FirestoreIds.sortedUids(b, a), [a, b]);
    expect(FirestoreIds.petIdsForUsers([a, b]), [a, b]);
    expect(
      FirestoreIds.blockId(blockerId: a, blockedId: b),
      'aaaaaaaaaaaaaaaa_bbbbbbbbbbbbbbbb',
    );
    expect(
      FirestoreIds.photoPath(petId: a, fileName: 'photo_1'),
      'pets/aaaaaaaaaaaaaaaa/photo_1',
    );
    expect(FirestoreIds.seedFromPhotoPath('pets/$a/photo_7'), 7);
  });

  test('IdentityContract lists every MVP collection', () {
    expect(IdentityContract.usersCollection, 'users');
    expect(IdentityContract.petsCollection, 'pets');
    expect(IdentityContract.likesCollection, 'likes');
    expect(IdentityContract.matchesCollection, 'matches');
    expect(IdentityContract.threadsCollection, 'threads');
    expect(IdentityContract.messagesCollection, 'messages');
    expect(IdentityContract.meetProposalsCollection, 'meetProposals');
    expect(IdentityContract.blocksCollection, 'blocks');
    expect(IdentityContract.reportsCollection, 'reports');
    expect(IdentityContract.functionsRegion, 'asia-northeast3');
    expect(IdentityContract.markUserVerifiedCallable, 'markUserVerified');
    expect(IdentityContract.verifiedAtField, 'verifiedAt');
  });

  test('without Auth the app stays on the mock data path', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(IdentityRemote.isLiveAuthReady, isFalse);
    expect(container.read(useMockDataProvider), isTrue);
  });

  test('pet codec writes rule-shaped fields and never verifiedAt', () {
    const uid = 'abcdefghijklmnopqrstuvwx';
    const draft = ProfileDraft(
      petName: '초코',
      species: PetSpecies.dog,
      breed: '말티즈',
      ageYears: 3,
      gender: PetGender.male,
      size: PetSize.small,
      photos: [MockPhoto(id: 'photo_0', seed: 4)],
      primaryPhotoId: 'photo_0',
      tags: {
        'walk_lover',
        'park_lover',
        'social_butterfly',
      },
      preferredTimeSlots: {PreferredTimeSlot.weekendMorning},
      bio: '공원 좋아해요',
    );
    final map = PetCodec.toFirestore(uid: uid, draft: draft);
    expect(map['ownerId'], uid);
    expect(map['name'], '초코');
    expect(map['species'], 'dog');
    expect(map['sex'], 'male');
    expect(map['size'], 'small');
    expect(map['age'], 3);
    expect(map['photos'], ['pets/$uid/photo_4']);
    expect(map['tags'], hasLength(3));
    expect(map['preferredTimeSlots'], ['weekendMorning']);
    expect(map.containsKey('verifiedAt'), isFalse);
    expect(map.containsKey(IdentityContract.verifiedAtField), isFalse);

    final profile = PetCodec.toDiscovery(uid, {
      ...map,
      'photos': map['photos'],
      'tags': map['tags'],
      'preferredTimeSlots': map['preferredTimeSlots'],
    });
    expect(profile, isNotNull);
    expect(profile!.id, uid);
    expect(profile.name, '초코');
    expect(profile.photoSeeds, [4]);
  });

  test('mock like uses fromUid_toPetId and sorted match ids', () async {
    final repo = MockSocialRepository(catalog: MockCatalog.profiles);
    addTearDown(repo.dispose);
    const me = 'mockuser00000001';
    final kong = MockCatalog.byId('kong')!;
    expect(kong.likedMe, isTrue);

    final matched = await repo.sendLike(fromUid: me, to: kong);
    expect(matched, isTrue);
    expect(repo.likes, hasLength(1));
    expect(repo.likes.single.id, '${me}_kong');
    expect(repo.likes.single.fromUid, me);
    expect(repo.likes.single.toPetId, 'kong');
    expect(repo.likes.single.toOwnerId, 'kong');

    final matchId = FirestoreIds.matchId(me, 'kong');
    expect(repo.matches, hasLength(1));
    expect(repo.matches.single.id, matchId);
    final uids = FirestoreIds.sortedUids(me, 'kong');
    expect(repo.matches.single.userIds, uids);
    expect(repo.matches.single.petIds, uids);
  });

  test('mock one-way like does not create a match', () async {
    final repo = MockSocialRepository(catalog: MockCatalog.profiles);
    addTearDown(repo.dispose);
    final bori = MockCatalog.byId('bori')!;
    expect(bori.likedMe, isFalse);
    final matched =
        await repo.sendLike(fromUid: 'mockuser00000001', to: bori);
    expect(matched, isFalse);
    expect(repo.matches, isEmpty);
    expect(repo.likes.single.id, 'mockuser00000001_bori');
  });

  test('mock chat and meetup stay on the match id thread', () async {
    final repo = MockSocialRepository(catalog: MockCatalog.profiles);
    addTearDown(repo.dispose);
    const me = 'mockuser00000001';
    final kong = MockCatalog.byId('kong')!;
    await repo.sendLike(fromUid: me, to: kong);
    final matchId = FirestoreIds.matchId(me, 'kong');

    await repo.sendText(matchId: matchId, senderId: me, text: '안녕');
    await repo.sendMeetup(
      matchId: matchId,
      fromUid: me,
      proposal: const MeetupProposal(
        place: MeetupPlace.park,
        placeDetail: '',
        timeLabel: '주말 아침',
        memo: '',
      ),
    );

    final threads = await repo.watchThreads(myUid: me).first;
    expect(threads, hasLength(1));
    expect(threads.single.id, matchId);
    expect(threads.single.messages.any((m) => m.text == '안녕'), isTrue);
    expect(
      threads.single.messages.any((m) => m.kind == ChatMessageKind.meetup),
      isTrue,
    );
  });

  test('mock report and block payloads match rules collections', () async {
    final repo = MockSocialRepository();
    addTearDown(repo.dispose);
    await repo.reportTarget(
      reporterId: 'mockuser00000001',
      targetType: 'pet',
      targetId: 'kong',
      reason: 'other',
    );
    expect(repo.reports.single['targetType'], 'pet');
    expect(repo.reports.single['reason'], 'other');
    await repo.blockUser(
      blockerId: 'mockuser00000001',
      blockedId: 'kong',
    );
    final blocked =
        await repo.watchBlockedIds(blockerId: 'mockuser00000001').first;
    expect(blocked, contains('kong'));
  });
}
