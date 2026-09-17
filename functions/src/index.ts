import {setGlobalOptions} from "firebase-functions";
import {onCall, HttpsError} from "firebase-functions/https";
import {callerUid, requirePhoneNumber} from "./caller";
import {auth, db} from "./firebase";
import {deleteOwnAccountForUid} from "./deleteOwnAccount";
import {setVerifiedAtForUid} from "./verifiedAt";

// Seoul — keep callables and Firestore triggers next to Firestore.
setGlobalOptions({
  region: "asia-northeast3",
  maxInstances: 10,
});

/**
 * A02 success path after Firebase Phone SMS link.
 *
 * Requires Firebase Auth with a `phone_number` claim (phone linked to the
 * Google/Apple account). Always writes `users/{caller.uid}` — never
 * another user's document. Returns `{ uid, verifiedAt }` (ISO-8601 UTC).
 */
export const markUserVerified = onCall(async (request) => {
  const uid = callerUid(request.auth?.uid, request.data?.uid);
  requirePhoneNumber(request.auth?.token?.phone_number);
  return setVerifiedAtForUid(db, uid);
});

/**
 * App Store account deletion: wipe caller Firestore data + Auth user.
 * Returns `{ uid }`. Client clears local session after success.
 */
export const deleteOwnAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  return deleteOwnAccountForUid(db, auth, uid);
});

export {onMessageCreated} from "./onMessageCreated";
export {onMatchCreated} from "./onMatchCreated";
export {
  onMeetProposalCreated,
  onMeetProposalUpdated,
} from "./onMeetProposal";
