import {
  type CollectionReference,
  type DocumentReference,
  type Firestore,
  type Query,
} from "firebase-admin/firestore";
import {type Auth} from "firebase-admin/auth";
import {HttpsError} from "firebase-functions/https";
import {logger} from "firebase-functions";

const BATCH_LIMIT = 400;

/**
 * Deletes Firestore data owned by or tied to [uid], then deletes the Auth user.
 * Idempotent on missing docs. Call only for the signed-in caller.
 */
export async function deleteOwnAccountForUid(
  db: Firestore,
  auth: Auth,
  uid: string,
): Promise<{uid: string}> {
  if (!uid || uid.length < 16) {
    throw new HttpsError("invalid-argument", "Invalid uid.");
  }

  await deleteUserFirestoreData(db, uid);

  try {
    await auth.deleteUser(uid);
  } catch (error: unknown) {
    const code =
      error && typeof error === "object" && "code" in error
        ? String((error as {code: unknown}).code)
        : "";
    if (code !== "auth/user-not-found") {
      logger.error("deleteOwnAccount Auth delete failed", {uid, error});
      throw new HttpsError("internal", "Failed to delete Auth user.");
    }
  }

  logger.info("deleteOwnAccount completed", {uid});
  return {uid};
}

export async function deleteUserFirestoreData(
  db: Firestore,
  uid: string,
): Promise<void> {
  const matchSnap = await db
    .collection("matches")
    .where("userIds", "array-contains", uid)
    .get();

  for (const matchDoc of matchSnap.docs) {
    const matchId = matchDoc.id;
    await deleteCollection(db.collection("threads").doc(matchId).collection("messages"));
    await deleteByQuery(
      db.collection("meetProposals").where("matchId", "==", matchId),
    );
    await safeDelete(db.collection("threads").doc(matchId));
    await safeDelete(matchDoc.ref);
  }

  await deleteByQuery(db.collection("likes").where("fromUid", "==", uid));
  await deleteByQuery(db.collection("likes").where("toOwnerId", "==", uid));
  await deleteByQuery(db.collection("blocks").where("blockerId", "==", uid));
  await deleteCollection(
    db.collection("users").doc(uid).collection("fcmTokens"),
  );
  await safeDelete(db.collection("pets").doc(uid));
  await safeDelete(db.collection("users").doc(uid));
}

async function deleteByQuery(query: Query): Promise<void> {
  while (true) {
    const snap = await query.limit(BATCH_LIMIT).get();
    if (snap.empty) return;
    const batch = snap.docs[0].ref.firestore.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    if (snap.size < BATCH_LIMIT) return;
  }
}

async function deleteCollection(
  col: CollectionReference,
): Promise<void> {
  while (true) {
    const snap = await col.limit(BATCH_LIMIT).get();
    if (snap.empty) return;
    const batch = col.firestore.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    if (snap.size < BATCH_LIMIT) return;
  }
}

async function safeDelete(ref: DocumentReference): Promise<void> {
  try {
    await ref.delete();
  } catch (error: unknown) {
    logger.warn("deleteOwnAccount safeDelete", {
      path: ref.path,
      error,
    });
  }
}
