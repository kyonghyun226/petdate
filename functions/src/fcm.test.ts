import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
  chunkArray,
  isStaleTokenError,
  loadRecipientTokens,
  otherParticipantUids,
  sendPushToUids,
  shouldNotifyMeetProposalUpdate,
  toFcmData,
} from "./fcm";
import type {Firestore} from "firebase-admin/firestore";

const ALICE = "aaaaaaaaaaaaaaaaaaaa";
const BOB = "bbbbbbbbbbbbbbbbbbbb";

function fakeDb(
  tokensByUid: Record<
    string,
    Array<{token: string; deleted?: {value: boolean}}>
  >,
): Firestore {
  return {
    collection(name: string) {
      assert.equal(name, "users");
      return {
        doc(uid: string) {
          return {
            collection(sub: string) {
              assert.equal(sub, "fcmTokens");
              const rows = tokensByUid[uid] ?? [];
              return {
                async get() {
                  return {
                    docs: rows.map((row) => ({
                      get(field: string) {
                        return field === "token" ? row.token : undefined;
                      },
                      ref: {
                        async delete() {
                          row.deleted = row.deleted ?? {value: false};
                          row.deleted.value = true;
                        },
                      },
                    })),
                  };
                },
              };
            },
          };
        },
      };
    },
  } as unknown as Firestore;
}

describe("otherParticipantUids", () => {
  it("returns both members when nobody is excluded", () => {
    assert.deepEqual(otherParticipantUids([ALICE, BOB]), [ALICE, BOB]);
  });

  it("excludes the sender and drops duplicates", () => {
    assert.deepEqual(otherParticipantUids([ALICE, BOB, ALICE], ALICE), [BOB]);
  });

  it("returns empty for missing or invalid userIds", () => {
    assert.deepEqual(otherParticipantUids(undefined, ALICE), []);
    assert.deepEqual(otherParticipantUids("nope", ALICE), []);
    assert.deepEqual(otherParticipantUids([1, "", ALICE], ALICE), []);
  });
});

describe("isStaleTokenError", () => {
  it("detects unregistered and invalid registration tokens", () => {
    assert.equal(
      isStaleTokenError({
        code: "messaging/registration-token-not-registered",
      }),
      true,
    );
    assert.equal(
      isStaleTokenError({code: "messaging/invalid-registration-token"}),
      true,
    );
    assert.equal(isStaleTokenError({code: "messaging/internal-error"}), false);
    assert.equal(isStaleTokenError(undefined), false);
  });
});

describe("toFcmData", () => {
  it("includes optional proposal fields as strings", () => {
    assert.deepEqual(
      toFcmData({
        matchId: `${ALICE}_${BOB}`,
        type: "meet_proposal",
        proposalId: "p1",
        status: "accepted",
      }),
      {
        matchId: `${ALICE}_${BOB}`,
        type: "meet_proposal",
        proposalId: "p1",
        status: "accepted",
      },
    );
    assert.deepEqual(
      toFcmData({matchId: "m", type: "message"}),
      {matchId: "m", type: "message"},
    );
  });
});

describe("shouldNotifyMeetProposalUpdate", () => {
  it("notifies only accepted and counter transitions", () => {
    assert.equal(shouldNotifyMeetProposalUpdate("pending", "accepted"), true);
    assert.equal(shouldNotifyMeetProposalUpdate("pending", "counter"), true);
    assert.equal(shouldNotifyMeetProposalUpdate("pending", "dismissed"), false);
    assert.equal(shouldNotifyMeetProposalUpdate("accepted", "accepted"), false);
  });
});

describe("chunkArray", () => {
  it("splits into sized batches and leaves a short tail", () => {
    assert.deepEqual(chunkArray([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
    assert.deepEqual(chunkArray([], 2), []);
  });
});

describe("sendPushToUids", () => {
  it("skips Admin FCM when no tokens are stored", async () => {
    let called = false;
    const result = await sendPushToUids(
      fakeDb({}),
      {
        async sendEachForMulticast() {
          called = true;
          return {successCount: 0, failureCount: 0, responses: []};
        },
      },
      [ALICE],
      {title: "반짝산책", body: "새 메시지가 도착했어요"},
      {matchId: `${ALICE}_${BOB}`, type: "message"},
    );
    assert.equal(called, false);
    assert.deepEqual(result, {attempted: 0, success: 0, staleRemoved: 0});
  });

  it("fans out unique tokens and deletes stale ones", async () => {
    const stale = {token: "stale-token-aaaaaaaaaaaaaaaa", deleted: {value: false}};
    const live = {token: "live-token-bbbbbbbbbbbbbbbbb", deleted: {value: false}};
    const dup = {token: "live-token-bbbbbbbbbbbbbbbbb", deleted: {value: false}};
    const sent: string[] = [];

    const result = await sendPushToUids(
      fakeDb({
        [ALICE]: [stale],
        [BOB]: [live, dup],
      }),
      {
        async sendEachForMulticast(message) {
          sent.push(...message.tokens);
          return {
            successCount: 1,
            failureCount: 1,
            responses: [
              {
                success: false,
                error: {
                  code: "messaging/registration-token-not-registered",
                },
              },
              {success: true},
            ],
          };
        },
      },
      [ALICE, BOB],
      {title: "반짝산책", body: "산책 메이트와 연결됐어요"},
      {matchId: `${ALICE}_${BOB}`, type: "match"},
    );

    assert.deepEqual(sent, [stale.token, live.token]);
    assert.equal(stale.deleted.value, true);
    assert.equal(live.deleted.value, false);
    assert.deepEqual(result, {attempted: 2, success: 1, staleRemoved: 1});
  });

  it("loads tokens from users/{uid}/fcmTokens", async () => {
    const tokens = await loadRecipientTokens(
      fakeDb({
        [BOB]: [{token: "only-bob-token-32-chars-minimum"}],
      }),
      [BOB],
    );
    assert.equal(tokens.length, 1);
    assert.equal(tokens[0].token, "only-bob-token-32-chars-minimum");
  });
});
