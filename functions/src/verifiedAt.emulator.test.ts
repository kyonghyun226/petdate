import assert from "node:assert/strict";
import {after, before, describe, it} from "node:test";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/https";
import {setVerifiedAtForUid} from "./verifiedAt";

const emulator = process.env.FIRESTORE_EMULATOR_HOST;
const describeIfEmulator = emulator ? describe : describe.skip;

describeIfEmulator("setVerifiedAtForUid (firestore emulator)", () => {
  const app = initializeApp({projectId: "petdatinglove"}, "verifiedAt-emulator");
  const db = getFirestore(app);

  before(async () => {
    await db.collection("users").doc("alice").set({
      goal: "walk",
      searchRadiusKm: 5,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  after(async () => {
    await app.delete();
  });

  it("sets verifiedAt and is idempotent", async () => {
    const first = await setVerifiedAtForUid(db, "alice");
    assert.equal(first.uid, "alice");
    const firstAt = Date.parse(first.verifiedAt);
    assert.ok(Number.isFinite(firstAt));

    const snap = await db.collection("users").doc("alice").get();
    const stored = snap.get("verifiedAt");
    assert.ok(stored instanceof Timestamp);
    assert.equal(stored.toDate().toISOString(), first.verifiedAt);

    const second = await setVerifiedAtForUid(db, "alice");
    assert.equal(second.verifiedAt, first.verifiedAt);
    const again = await db.collection("users").doc("alice").get();
    assert.equal(
      (again.get("verifiedAt") as Timestamp).toDate().toISOString(),
      first.verifiedAt,
    );
  });

  it("does not create a stub user document", async () => {
    await assert.rejects(
      () => setVerifiedAtForUid(db, "missing-user"),
      (err: unknown) =>
        err instanceof HttpsError && err.code === "failed-precondition",
    );
    const snap = await db.collection("users").doc("missing-user").get();
    assert.equal(snap.exists, false);
  });
});
