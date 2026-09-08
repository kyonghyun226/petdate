/**
 * Firestore rules contract tests for 반짝산책 (petdate).
 *
 * Run from repo root (emulator must be up, or use firebase emulators:exec):
 *   npx -y firebase-tools@latest emulators:exec --only firestore --project petdatinglove \
 *     "npm test --prefix firebase/rules-tests"
 */
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const RULES = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');

const ALICE = 'aaaaaaaaaaaaaaaaaaaa';
const BOB = 'bbbbbbbbbbbbbbbbbbbb';
const EVE = 'eeeeeeeeeeeeeeeeeeee';
const PAIR_AB = `${ALICE}_${BOB}`;

let env;

function db(uid) {
  return env.authenticatedContext(uid).firestore();
}

function unauth() {
  return env.unauthenticatedContext().firestore();
}

function userDoc(uid, extra = {}) {
  return {
    uid,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    onboardingCompleted: true,
    profileCompleted: true,
    goal: 'walk',
    ...extra,
  };
}

function publishedPet(ownerId, extra = {}) {
  return {
    ownerId,
    name: '초코',
    species: 'dog',
    breed: '말티즈',
    gender: 'male',
    size: 'small',
    ageYears: 3,
    tags: ['산책 좋아해요', '공원 러버', '친구 많아요'],
    bio: '주말 한강',
    photoPaths: [`pets/${ownerId}/primary.jpg`],
    primaryPhotoIndex: 0,
    preferredTimeSlots: ['weekendMorning'],
    goal: 'walk',
    isPublished: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra,
  };
}

function draftPet(ownerId, extra = {}) {
  return {
    ownerId,
    tags: [],
    bio: '',
    photoPaths: [],
    primaryPhotoIndex: 0,
    preferredTimeSlots: [],
    isPublished: false,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extra,
  };
}

async function seed(write) {
  await env.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await write(firestore);
  });
}

describe('petdate firestore.rules', () => {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: 'petdatinglove-rules-test',
      firestore: { rules: RULES },
    });
  });

  after(async () => {
    await env?.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
  });

  describe('default deny / unauthenticated', () => {
    it('denies unauthenticated user read', async () => {
      await seed(async (fs) => {
        await setDoc(doc(fs, 'users', ALICE), userDoc(ALICE));
        await setDoc(doc(fs, 'pets', ALICE), publishedPet(ALICE));
      });
      await assertFails(getDoc(doc(unauth(), 'users', ALICE)));
      await assertFails(getDoc(doc(unauth(), 'pets', ALICE)));
    });

    it('denies unknown collections', async () => {
      await assertFails(
        setDoc(doc(db(ALICE), 'secrets', 'x'), { uid: ALICE }),
      );
      await assertFails(getDoc(doc(db(ALICE), 'admin', 'config')));
    });
  });

  describe('users/{uid}', () => {
    it('allows owner create/read/update with valid schema', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'users', ALICE), userDoc(ALICE)),
      );
      await assertSucceeds(getDoc(doc(db(ALICE), 'users', ALICE)));
      await assertSucceeds(
        updateDoc(doc(db(ALICE), 'users', ALICE), {
          goal: 'friend',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('denies reading or writing another user', async () => {
      await seed(async (fs) => {
        await setDoc(doc(fs, 'users', ALICE), userDoc(ALICE));
      });
      await assertFails(getDoc(doc(db(BOB), 'users', ALICE)));
      await assertFails(
        setDoc(doc(db(BOB), 'users', ALICE), userDoc(ALICE)),
      );
      await assertFails(
        updateDoc(doc(db(BOB), 'users', ALICE), {
          goal: 'friend',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('denies extra fields, missing uid, and spoofed uid', async () => {
      await assertFails(
        setDoc(doc(db(ALICE), 'users', ALICE), {
          ...userDoc(ALICE),
          email: 'alice@example.com',
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'users', ALICE), {
          ...userDoc(ALICE),
          isAdmin: true,
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'users', BOB), userDoc(BOB)),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'users', ALICE), {
          ...userDoc(ALICE),
          uid: BOB,
        }),
      );
    });

    it('denies changing uid or createdAt on update', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'users', ALICE), userDoc(ALICE)),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'users', ALICE), {
          uid: BOB,
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'users', ALICE), {
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }),
      );
    });
  });

  describe('pets/{uid}', () => {
    it('allows owner to save an unpublished draft', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'pets', ALICE), draftPet(ALICE)),
      );
    });

    it('hides unpublished pets from others; allows published explore reads', async () => {
      await seed(async (fs) => {
        await setDoc(doc(fs, 'pets', ALICE), publishedPet(ALICE));
        await setDoc(doc(fs, 'pets', BOB), publishedPet(BOB, { name: '나비' }));
        await setDoc(doc(fs, 'pets', EVE), draftPet(EVE));
      });
      await assertSucceeds(getDoc(doc(db(BOB), 'pets', ALICE)));
      await assertFails(getDoc(doc(db(ALICE), 'pets', EVE)));
      await assertSucceeds(getDoc(doc(db(EVE), 'pets', EVE)));
      await assertFails(getDocs(collection(db(ALICE), 'pets')));
      await assertSucceeds(
        getDocs(
          query(collection(db(ALICE), 'pets'), where('isPublished', '==', true)),
        ),
      );
    });

    it('rejects published pets missing required explore fields', async () => {
      await assertFails(
        setDoc(doc(db(ALICE), 'pets', ALICE), {
          ...draftPet(ALICE),
          isPublished: true,
        }),
      );
    });

    it('rejects oversized bio, extra fields, and path traversal photos', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'pets', ALICE), publishedPet(ALICE)),
      );
      await assertSucceeds(
        updateDoc(doc(db(ALICE), 'pets', ALICE), {
          bio: '꼬리가 먼저 반짝해요',
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'pets', ALICE), {
          bio: 'x'.repeat(141),
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'pets', ALICE), {
          email: 'hidden@example.com',
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'pets', ALICE), {
          photoPaths: [`pets/${BOB}/stolen.jpg`],
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'pets', ALICE), {
          ownerId: BOB,
          updatedAt: serverTimestamp(),
        }),
      );
    });
  });

  describe('likes / passes / blocks', () => {
    async function seedPublishedPair() {
      await seed(async (fs) => {
        await setDoc(doc(fs, 'pets', ALICE), publishedPet(ALICE));
        await setDoc(doc(fs, 'pets', BOB), publishedPet(BOB));
      });
    }

    it('allows a user to like a published pet as themselves only', async () => {
      await seedPublishedPair();
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'likes', `${ALICE}_${BOB}`), {
          fromUid: ALICE,
          toUid: BOB,
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'likes', `${BOB}_${ALICE}`), {
          fromUid: BOB,
          toUid: ALICE,
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'likes', `${ALICE}_${EVE}`), {
          fromUid: ALICE,
          toUid: EVE,
          createdAt: serverTimestamp(),
        }),
      );
    });

    it('lets the recipient read a like but not update it', async () => {
      await seedPublishedPair();
      await setDoc(doc(db(ALICE), 'likes', `${ALICE}_${BOB}`), {
        fromUid: ALICE,
        toUid: BOB,
        createdAt: serverTimestamp(),
      });
      await assertSucceeds(getDoc(doc(db(BOB), 'likes', `${ALICE}_${BOB}`)));
      await assertFails(getDoc(doc(db(EVE), 'likes', `${ALICE}_${BOB}`)));
      await assertFails(
        updateDoc(doc(db(ALICE), 'likes', `${ALICE}_${BOB}`), {
          toUid: EVE,
        }),
      );
    });

    it('keeps passes private to the passer', async () => {
      await seedPublishedPair();
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'passes', `${ALICE}_${BOB}`), {
          fromUid: ALICE,
          toUid: BOB,
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(getDoc(doc(db(BOB), 'passes', `${ALICE}_${BOB}`)));
    });

    it('blocks like-create when either user has blocked the other', async () => {
      await seedPublishedPair();
      await setDoc(doc(db(BOB), 'blocks', `${BOB}_${ALICE}`), {
        blockerUid: BOB,
        blockedUid: ALICE,
        createdAt: serverTimestamp(),
      });
      await assertFails(
        setDoc(doc(db(ALICE), 'likes', `${ALICE}_${BOB}`), {
          fromUid: ALICE,
          toUid: BOB,
          createdAt: serverTimestamp(),
        }),
      );
    });

    it('allows blocker-only read/delete of blocks; denies self-block', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'blocks', `${ALICE}_${BOB}`), {
          blockerUid: ALICE,
          blockedUid: BOB,
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(getDoc(doc(db(BOB), 'blocks', `${ALICE}_${BOB}`)));
      await assertFails(
        setDoc(doc(db(ALICE), 'blocks', `${ALICE}_${ALICE}`), {
          blockerUid: ALICE,
          blockedUid: ALICE,
          createdAt: serverTimestamp(),
        }),
      );
      await assertSucceeds(
        deleteDoc(doc(db(ALICE), 'blocks', `${ALICE}_${BOB}`)),
      );
    });
  });

  describe('matches / chats / messages / meetups', () => {
    async function seedMutualLikes() {
      await seed(async (fs) => {
        await setDoc(doc(fs, 'pets', ALICE), publishedPet(ALICE));
        await setDoc(doc(fs, 'pets', BOB), publishedPet(BOB));
        await setDoc(doc(fs, 'likes', `${ALICE}_${BOB}`), {
          fromUid: ALICE,
          toUid: BOB,
          createdAt: serverTimestamp(),
        });
        await setDoc(doc(fs, 'likes', `${BOB}_${ALICE}`), {
          fromUid: BOB,
          toUid: ALICE,
          createdAt: serverTimestamp(),
        });
      });
    }

    it('denies match create without mutual likes', async () => {
      await seed(async (fs) => {
        await setDoc(doc(fs, 'pets', ALICE), publishedPet(ALICE));
        await setDoc(doc(fs, 'pets', BOB), publishedPet(BOB));
        await setDoc(doc(fs, 'likes', `${ALICE}_${BOB}`), {
          fromUid: ALICE,
          toUid: BOB,
          createdAt: serverTimestamp(),
        });
      });
      await assertFails(
        setDoc(doc(db(ALICE), 'matches', PAIR_AB), {
          participantIds: [ALICE, BOB],
          unmatched: false,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('allows match+chat after mutual likes; scopes chat to participants', async () => {
      await seedMutualLikes();
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'matches', PAIR_AB), {
          participantIds: [ALICE, BOB],
          unmatched: false,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }),
      );
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'chats', PAIR_AB), {
          participantIds: [ALICE, BOB],
          lastMessagePreview: '',
          lastMessageAt: serverTimestamp(),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }),
      );
      await assertSucceeds(getDoc(doc(db(BOB), 'chats', PAIR_AB)));
      await assertFails(getDoc(doc(db(EVE), 'chats', PAIR_AB)));
      await assertFails(getDoc(doc(db(EVE), 'matches', PAIR_AB)));
    });

    it('allows participant text messages and rejects outsider / system spoof', async () => {
      await seedMutualLikes();
      await seed(async (fs) => {
        await setDoc(doc(fs, 'matches', PAIR_AB), {
          participantIds: [ALICE, BOB],
          unmatched: false,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
        await setDoc(doc(fs, 'chats', PAIR_AB), {
          participantIds: [ALICE, BOB],
          lastMessagePreview: '',
          lastMessageAt: serverTimestamp(),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      });
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'chats', PAIR_AB, 'messages', 'm1'), {
          senderId: ALICE,
          kind: 'text',
          text: '안녕',
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'chats', PAIR_AB, 'messages', 'm2'), {
          senderId: ALICE,
          kind: 'system',
          text: '매칭됨',
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(
        setDoc(doc(db(EVE), 'chats', PAIR_AB, 'messages', 'm3'), {
          senderId: EVE,
          kind: 'text',
          text: 'hello',
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'chats', PAIR_AB, 'messages', 'm1'), {
          text: 'edited',
        }),
      );
    });

    it('enforces meetup transitions and blocks invalid jumps', async () => {
      await seedMutualLikes();
      await seed(async (fs) => {
        await setDoc(doc(fs, 'matches', PAIR_AB), {
          participantIds: [ALICE, BOB],
          unmatched: false,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
        await setDoc(doc(fs, 'chats', PAIR_AB), {
          participantIds: [ALICE, BOB],
          lastMessagePreview: '',
          lastMessageAt: serverTimestamp(),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      });
      const meetupRef = doc(db(ALICE), 'chats', PAIR_AB, 'meetups', 'meet1');
      await assertSucceeds(
        setDoc(meetupRef, {
          proposerId: ALICE,
          receiverId: BOB,
          place: 'park',
          placeDetail: '',
          timeLabel: '토요일 오후 3시',
          memo: '',
          status: 'pending',
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(meetupRef, {
          status: 'accepted',
          updatedAt: serverTimestamp(),
        }),
      );
      await assertSucceeds(
        updateDoc(doc(db(BOB), 'chats', PAIR_AB, 'meetups', 'meet1'), {
          status: 'accepted',
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(db(BOB), 'chats', PAIR_AB, 'meetups', 'meet1'), {
          status: 'declined',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('stops messages after unmatch', async () => {
      await seedMutualLikes();
      await seed(async (fs) => {
        await setDoc(doc(fs, 'matches', PAIR_AB), {
          participantIds: [ALICE, BOB],
          unmatched: false,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
        await setDoc(doc(fs, 'chats', PAIR_AB), {
          participantIds: [ALICE, BOB],
          lastMessagePreview: '',
          lastMessageAt: serverTimestamp(),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      });
      await assertSucceeds(
        updateDoc(doc(db(ALICE), 'matches', PAIR_AB), {
          unmatched: true,
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'chats', PAIR_AB, 'messages', 'late'), {
          senderId: ALICE,
          kind: 'text',
          text: 'still here',
          createdAt: serverTimestamp(),
        }),
      );
    });
  });

  describe('reports', () => {
    it('allows reporter create/read and denies mutation or peer read', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'reports', 'r1'), {
          reporterUid: ALICE,
          targetUid: BOB,
          targetType: 'user',
          reason: 'spam',
          details: '',
          createdAt: serverTimestamp(),
        }),
      );
      await assertSucceeds(getDoc(doc(db(ALICE), 'reports', 'r1')));
      await assertFails(getDoc(doc(db(BOB), 'reports', 'r1')));
      await assertFails(
        updateDoc(doc(db(ALICE), 'reports', 'r1'), { reason: 'other' }),
      );
      await assertFails(deleteDoc(doc(db(ALICE), 'reports', 'r1')));
    });
  });
});
