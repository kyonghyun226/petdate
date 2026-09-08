/**
 * Official MVP Firestore contract tests for 반짝산책 (petdate).
 *
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

function userDoc(extra = {}) {
  return {
    goal: 'walk',
    searchRadiusKm: 5,
    createdAt: serverTimestamp(),
    ...extra,
  };
}

function petDoc(ownerId, extra = {}) {
  return {
    ownerId,
    name: '초코',
    species: 'dog',
    breed: '말티즈',
    age: 3,
    sex: 'male',
    size: 'small',
    photos: [`pets/${ownerId}/primary.jpg`],
    tags: ['walk_lover', 'park_lover', 'cafe_lover'],
    bio: '주말 한강',
    preferredTimeSlots: ['weekendMorning'],
    updatedAt: serverTimestamp(),
    ...extra,
  };
}

async function seed(write) {
  await env.withSecurityRulesDisabled(async (context) => {
    await write(context.firestore());
  });
}

async function seedVerifiedPair() {
  await seed(async (fs) => {
    await setDoc(doc(fs, 'users', ALICE), {
      ...userDoc(),
      verifiedAt: serverTimestamp(),
    });
    await setDoc(doc(fs, 'users', BOB), {
      ...userDoc(),
      verifiedAt: serverTimestamp(),
    });
    await setDoc(doc(fs, 'pets', ALICE), petDoc(ALICE));
    await setDoc(doc(fs, 'pets', BOB), petDoc(BOB, { name: '나비' }));
  });
}

describe('petdate official MVP firestore.rules', () => {
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

  describe('default deny', () => {
    it('denies unauthenticated reads of users and pets', async () => {
      await seed(async (fs) => {
        await setDoc(doc(fs, 'users', ALICE), userDoc());
        await setDoc(doc(fs, 'pets', ALICE), petDoc(ALICE));
      });
      await assertFails(getDoc(doc(unauth(), 'users', ALICE)));
      await assertFails(getDoc(doc(unauth(), 'pets', ALICE)));
    });

    it('denies unknown collections', async () => {
      await assertFails(setDoc(doc(db(ALICE), 'chats', 'x'), { a: 1 }));
      await assertFails(setDoc(doc(db(ALICE), 'passes', 'x'), { a: 1 }));
      await assertFails(getDoc(doc(db(ALICE), 'admin', 'config')));
    });
  });

  describe('users/{uid}', () => {
    it('allows owner create/read/update without self-setting verifiedAt', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'users', ALICE), userDoc()),
      );
      await assertSucceeds(getDoc(doc(db(ALICE), 'users', ALICE)));
      await assertSucceeds(
        updateDoc(doc(db(ALICE), 'users', ALICE), { goal: 'friend' }),
      );
    });

    it('denies peer read/write, extra fields, and client verifiedAt', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'users', ALICE), userDoc()),
      );
      await assertFails(getDoc(doc(db(BOB), 'users', ALICE)));
      await assertFails(
        setDoc(doc(db(ALICE), 'users', ALICE), {
          ...userDoc(),
          email: 'alice@example.com',
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'users', ALICE), {
          ...userDoc(),
          verifiedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'users', BOB), userDoc()),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'users', ALICE), {
          createdAt: serverTimestamp(),
        }),
      );
    });

    it('rejects searchRadiusKm outside 1–50', async () => {
      await assertFails(
        setDoc(doc(db(ALICE), 'users', ALICE), {
          ...userDoc(),
          searchRadiusKm: 0,
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'users', ALICE), {
          ...userDoc(),
          searchRadiusKm: 51,
        }),
      );
    });
  });

  describe('pets/{petId}', () => {
    it('lets any signed-in user read explore cards; owner writes', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'pets', ALICE), petDoc(ALICE)),
      );
      await assertSucceeds(getDoc(doc(db(BOB), 'pets', ALICE)));
      await assertSucceeds(getDocs(collection(db(BOB), 'pets')));
      await assertSucceeds(
        updateDoc(doc(db(ALICE), 'pets', ALICE), {
          bio: '꼬리가 먼저 반짝해요',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    it('rejects invalid tags, oversized bio, and photo path escape', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'pets', ALICE), petDoc(ALICE)),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'pets', ALICE), {
          tags: ['walk_lover', 'not_a_real_tag', 'park_lover'],
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
          photos: [`pets/${BOB}/stolen.jpg`],
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'pets', BOB), petDoc(ALICE)),
      );
    });
  });

  describe('likes', () => {
    it('denies likes when verifiedAt is missing', async () => {
      await seed(async (fs) => {
        await setDoc(doc(fs, 'users', ALICE), userDoc());
        await setDoc(doc(fs, 'pets', BOB), petDoc(BOB));
      });
      await assertFails(
        setDoc(doc(db(ALICE), 'likes', `${ALICE}_${BOB}`), {
          fromUid: ALICE,
          toPetId: BOB,
          toOwnerId: BOB,
          createdAt: serverTimestamp(),
        }),
      );
    });

    it('allows verified creator create/read/delete; recipient read', async () => {
      await seedVerifiedPair();
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'likes', `${ALICE}_${BOB}`), {
          fromUid: ALICE,
          toPetId: BOB,
          toOwnerId: BOB,
          createdAt: serverTimestamp(),
        }),
      );
      await assertSucceeds(getDoc(doc(db(ALICE), 'likes', `${ALICE}_${BOB}`)));
      await assertSucceeds(getDoc(doc(db(BOB), 'likes', `${ALICE}_${BOB}`)));
      await assertFails(getDoc(doc(db(EVE), 'likes', `${ALICE}_${BOB}`)));
      await assertFails(
        setDoc(doc(db(ALICE), 'likes', `${BOB}_${ALICE}`), {
          fromUid: BOB,
          toPetId: ALICE,
          toOwnerId: ALICE,
          createdAt: serverTimestamp(),
        }),
      );
      await assertSucceeds(
        deleteDoc(doc(db(ALICE), 'likes', `${ALICE}_${BOB}`)),
      );
    });
  });

  describe('matches / threads / messages / meetProposals', () => {
    async function seedMutualLikes() {
      await seedVerifiedPair();
      await seed(async (fs) => {
        await setDoc(doc(fs, 'likes', `${ALICE}_${BOB}`), {
          fromUid: ALICE,
          toPetId: BOB,
          toOwnerId: BOB,
          createdAt: serverTimestamp(),
        });
        await setDoc(doc(fs, 'likes', `${BOB}_${ALICE}`), {
          fromUid: BOB,
          toPetId: ALICE,
          toOwnerId: ALICE,
          createdAt: serverTimestamp(),
        });
      });
    }

    it('denies match create without mutual likes', async () => {
      await seedVerifiedPair();
      await seed(async (fs) => {
        await setDoc(doc(fs, 'likes', `${ALICE}_${BOB}`), {
          fromUid: ALICE,
          toPetId: BOB,
          toOwnerId: BOB,
          createdAt: serverTimestamp(),
        });
      });
      await assertFails(
        setDoc(doc(db(ALICE), 'matches', PAIR_AB), {
          userIds: [ALICE, BOB],
          petIds: [ALICE, BOB],
          createdAt: serverTimestamp(),
        }),
      );
    });

    it('allows match+thread after mutual likes; scopes to participants', async () => {
      await seedMutualLikes();
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'matches', PAIR_AB), {
          userIds: [ALICE, BOB],
          petIds: [ALICE, BOB],
          createdAt: serverTimestamp(),
        }),
      );
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'threads', PAIR_AB), {
          lastMessage: '',
          updatedAt: serverTimestamp(),
        }),
      );
      await assertSucceeds(getDoc(doc(db(BOB), 'threads', PAIR_AB)));
      await assertFails(getDoc(doc(db(EVE), 'threads', PAIR_AB)));
      await assertFails(getDoc(doc(db(EVE), 'matches', PAIR_AB)));
    });

    it('allows participant text messages and rejects other types', async () => {
      await seedMutualLikes();
      await seed(async (fs) => {
        await setDoc(doc(fs, 'matches', PAIR_AB), {
          userIds: [ALICE, BOB],
          petIds: [ALICE, BOB],
          createdAt: serverTimestamp(),
        });
        await setDoc(doc(fs, 'threads', PAIR_AB), {
          lastMessage: '',
          updatedAt: serverTimestamp(),
        });
      });
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'threads', PAIR_AB, 'messages', 'm1'), {
          senderId: ALICE,
          type: 'text',
          text: '안녕',
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(
        setDoc(doc(db(ALICE), 'threads', PAIR_AB, 'messages', 'm2'), {
          senderId: ALICE,
          type: 'system',
          text: '매칭됨',
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(
        setDoc(doc(db(EVE), 'threads', PAIR_AB, 'messages', 'm3'), {
          senderId: EVE,
          type: 'text',
          text: 'hello',
          createdAt: serverTimestamp(),
        }),
      );
    });

    it('enforces meetProposal status transitions', async () => {
      await seedMutualLikes();
      await seed(async (fs) => {
        await setDoc(doc(fs, 'matches', PAIR_AB), {
          userIds: [ALICE, BOB],
          petIds: [ALICE, BOB],
          createdAt: serverTimestamp(),
        });
      });
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'meetProposals', 'p1'), {
          matchId: PAIR_AB,
          fromUid: ALICE,
          placeType: 'park',
          timeSlot: '토요일 오후 3시',
          status: 'pending',
        }),
      );
      await assertFails(
        updateDoc(doc(db(ALICE), 'meetProposals', 'p1'), {
          status: 'accepted',
        }),
      );
      await assertSucceeds(
        updateDoc(doc(db(BOB), 'meetProposals', 'p1'), {
          status: 'accepted',
        }),
      );
      await assertFails(
        updateDoc(doc(db(BOB), 'meetProposals', 'p1'), {
          status: 'dismissed',
        }),
      );
    });
  });

  describe('blocks / reports', () => {
    it('allows blocker-only read of blocks', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'blocks', `${ALICE}_${BOB}`), {
          blockerId: ALICE,
          blockedId: BOB,
        }),
      );
      await assertSucceeds(getDoc(doc(db(ALICE), 'blocks', `${ALICE}_${BOB}`)));
      await assertFails(getDoc(doc(db(BOB), 'blocks', `${ALICE}_${BOB}`)));
      await assertSucceeds(
        getDocs(
          query(
            collection(db(ALICE), 'blocks'),
            where('blockerId', '==', ALICE),
          ),
        ),
      );
    });

    it('allows reporter create and denies all client reads', async () => {
      await assertSucceeds(
        setDoc(doc(db(ALICE), 'reports', 'r1'), {
          reporterId: ALICE,
          targetType: 'user',
          targetId: BOB,
          reason: 'spam',
          createdAt: serverTimestamp(),
        }),
      );
      await assertFails(getDoc(doc(db(ALICE), 'reports', 'r1')));
      await assertFails(getDoc(doc(db(BOB), 'reports', 'r1')));
      await assertFails(deleteDoc(doc(db(ALICE), 'reports', 'r1')));
    });
  });

  describe('users/{uid}/fcmTokens/{tokenHash}', () => {
    const TOKEN_HASH =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    const FCM_TOKEN = 'fcm-device-token-value-at-least-32ch';

    function tokenDoc(extra = {}) {
      return {
        token: FCM_TOKEN,
        platform: 'ios',
        updatedAt: serverTimestamp(),
        ...extra,
      };
    }

    function tokenRef(uid, hash = TOKEN_HASH) {
      return doc(db(uid), 'users', uid, 'fcmTokens', hash);
    }

    it('allows owner create/read/update/delete and denies peers', async () => {
      await assertSucceeds(setDoc(tokenRef(ALICE), tokenDoc()));
      await assertSucceeds(getDoc(tokenRef(ALICE)));
      await assertSucceeds(
        getDocs(collection(db(ALICE), 'users', ALICE, 'fcmTokens')),
      );
      await assertSucceeds(
        setDoc(tokenRef(ALICE), tokenDoc({ platform: 'android' })),
      );
      await assertFails(
        getDoc(doc(db(BOB), 'users', ALICE, 'fcmTokens', TOKEN_HASH)),
      );
      await assertFails(
        getDocs(collection(db(BOB), 'users', ALICE, 'fcmTokens')),
      );
      await assertFails(
        setDoc(
          doc(db(BOB), 'users', ALICE, 'fcmTokens', TOKEN_HASH),
          tokenDoc(),
        ),
      );
      await assertFails(
        getDoc(doc(unauth(), 'users', ALICE, 'fcmTokens', TOKEN_HASH)),
      );
      await assertSucceeds(deleteDoc(tokenRef(ALICE)));
    });

    it('rejects raw token ids, extra fields, and invalid payloads', async () => {
      await assertFails(
        setDoc(
          doc(db(ALICE), 'users', ALICE, 'fcmTokens', FCM_TOKEN),
          tokenDoc(),
        ),
      );
      await assertFails(
        setDoc(
          doc(db(ALICE), 'users', ALICE, 'fcmTokens', TOKEN_HASH.toUpperCase()),
          tokenDoc(),
        ),
      );
      await assertFails(
        setDoc(tokenRef(ALICE), tokenDoc({ platform: 'web' })),
      );
      await assertFails(
        setDoc(tokenRef(ALICE), tokenDoc({ token: 'short' })),
      );
      await assertFails(
        setDoc(tokenRef(ALICE), tokenDoc({ extra: true })),
      );
      await assertFails(
        setDoc(tokenRef(ALICE), {
          token: FCM_TOKEN,
          platform: 'ios',
        }),
      );
      await assertSucceeds(setDoc(tokenRef(ALICE), tokenDoc()));
      await assertFails(
        updateDoc(tokenRef(ALICE), { platform: 'web' }),
      );
    });
  });
});
