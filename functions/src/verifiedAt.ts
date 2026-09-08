import {FieldValue, Timestamp, type Firestore} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/https";
import {logger} from "firebase-functions";

export type MarkVerifiedResult = {
  uid: string;
  verifiedAt: string;
};

/**
 * Admin-only write for `users/{uid}.verifiedAt`.
 *
 * firestore.rules deny client create/update of this field. Likes and match
 * creates require it to be a timestamp.
 *
 * Idempotent: if verifiedAt is already a timestamp, the original value is
 * kept and returned.
 *
 * Does not create a stub user doc. A document with only verifiedAt would
 * block the client's later `users/{uid}` create (and fail `isValidUser`
 * on update). A02 must run after the profile write, or keep a local flag
 * and call this once `users/{uid}` exists.
 *
 * Future Korean ID-provider webhook (PASS / NICE / KCB / etc.):
 *   1. Verify the vendor signature / allowlist — do not trust the body.
 *   2. Resolve the vendor session to a Firebase uid (never accept a raw
 *      uid from an unauthenticated caller).
 *   3. Call setVerifiedAtForUid(db, uid) — same Admin write as the A02
 *      callable. Do not add a public HTTPS endpoint that takes a uid.
 */
export async function setVerifiedAtForUid(
  db: Firestore,
  uid: string,
): Promise<MarkVerifiedResult> {
  const ref = db.collection("users").doc(uid);

  const existing = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError(
        "failed-precondition",
        `users/${uid} does not exist. Create the user profile first, then call markUserVerified.`,
      );
    }
    const current = snap.get("verifiedAt");
    if (current instanceof Timestamp) {
      return current;
    }
    tx.update(ref, {verifiedAt: FieldValue.serverTimestamp()});
    return null;
  });

  if (existing) {
    logger.info("markUserVerified idempotent", {uid});
    return {uid, verifiedAt: existing.toDate().toISOString()};
  }

  const after = await ref.get();
  const verifiedAt = after.get("verifiedAt");
  if (!(verifiedAt instanceof Timestamp)) {
    throw new HttpsError("internal", "verifiedAt was not persisted.");
  }
  logger.info("markUserVerified wrote verifiedAt", {uid});
  return {uid, verifiedAt: verifiedAt.toDate().toISOString()};
}
