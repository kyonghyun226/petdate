import assert from "node:assert/strict";
import {after, before, describe, it} from "node:test";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {deleteUserFirestoreData} from "./deleteOwnAccount";

const emulator = process.env.FIRESTORE_EMULATOR_HOST;
const describeIfEmulator = emulator ? describe : describe.skip;

describeIfEmulator("deleteUserFirestoreData (firestore emulator)", () => {
  const app = initializeApp({projectId: "petdatinglove"}, "delete-account-emulator");
  const db = getFirestore(app);
  const uid = "deleteuser0000001";
  const other = "deleteuser0000002";
  const matchId = `${uid}_${other}`;

  before(async () => {
    await db.collection("users").doc(uid).set({
      goal: "friend",
      searchRadiusKm: 5,
      createdAt: FieldValue.serverTimestamp(),
    });
    await db.collection("users").doc(uid).collection("fcmTokens").doc("a".repeat(64)).set({
      token: "t".repeat(40),
      platform: "ios",
      updatedAt: FieldValue.serverTimestamp(),
    });
    await db.collection("pets").doc(uid).set({
      ownerId: uid,
      name: "초코",
      species: "dog",
      breed: "말티즈",
      age: 2,
      sex: "female",
      size: "small",
      photos: [`pets/${uid}/photo_0`],
      tags: ["walk_lover", "cafe_lover", "nap_lover"],
      bio: "",
      preferredTimeSlots: ["weekendMorning"],
      updatedAt: FieldValue.serverTimestamp(),
    });
    await db.collection("likes").doc(`${uid}_${other}`).set({
      fromUid: uid,
      toPetId: other,
      toOwnerId: other,
      createdAt: FieldValue.serverTimestamp(),
    });
    await db.collection("likes").doc(`${other}_${uid}`).set({
      fromUid: other,
      toPetId: uid,
      toOwnerId: uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    await db.collection("blocks").doc(`${uid}_${other}`).set({
      blockerId: uid,
      blockedId: other,
    });
    await db.collection("matches").doc(matchId).set({
      userIds: [uid, other],
      petIds: [uid, other],
      createdAt: FieldValue.serverTimestamp(),
    });
    await db.collection("threads").doc(matchId).set({
      lastMessage: "hi",
      updatedAt: FieldValue.serverTimestamp(),
    });
    await db.collection("threads").doc(matchId).collection("messages").add({
      senderId: uid,
      text: "hello",
      type: "text",
      createdAt: FieldValue.serverTimestamp(),
    });
    await db.collection("meetProposals").add({
      matchId,
      fromUid: uid,
      placeType: "park",
      timeSlot: "오늘 저녁",
      status: "pending",
    });
  });

  after(async () => {
    await app.delete();
  });

  it("removes user-owned and related social documents", async () => {
    await deleteUserFirestoreData(db, uid);

    assert.equal((await db.collection("users").doc(uid).get()).exists, false);
    assert.equal((await db.collection("pets").doc(uid).get()).exists, false);
    assert.equal((await db.collection("likes").doc(`${uid}_${other}`).get()).exists, false);
    assert.equal((await db.collection("likes").doc(`${other}_${uid}`).get()).exists, false);
    assert.equal((await db.collection("blocks").doc(`${uid}_${other}`).get()).exists, false);
    assert.equal((await db.collection("matches").doc(matchId).get()).exists, false);
    assert.equal((await db.collection("threads").doc(matchId).get()).exists, false);
    const tokens = await db.collection("users").doc(uid).collection("fcmTokens").get();
    assert.equal(tokens.empty, true);
    const proposals = await db.collection("meetProposals").where("matchId", "==", matchId).get();
    assert.equal(proposals.empty, true);
  });
});
