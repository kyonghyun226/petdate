import {setGlobalOptions} from "firebase-functions";
import {onCall} from "firebase-functions/https";
import {callerUid} from "./caller";
import {db} from "./firebase";
import {setVerifiedAtForUid} from "./verifiedAt";

// Seoul — keep callables and Firestore triggers next to Firestore.
setGlobalOptions({
  region: "asia-northeast3",
  maxInstances: 10,
});

/**
 * A02 success path (mock or real ID UI).
 *
 * Requires Firebase Auth. Always writes `users/{caller.uid}` — never
 * another user's document. Returns `{ uid, verifiedAt }` (ISO-8601 UTC).
 */
export const markUserVerified = onCall(async (request) => {
  const uid = callerUid(request.auth?.uid, request.data?.uid);
  return setVerifiedAtForUid(db, uid);
});

export {onMessageCreated} from "./onMessageCreated";
export {onMatchCreated} from "./onMatchCreated";
export {
  onMeetProposalCreated,
  onMeetProposalUpdated,
} from "./onMeetProposal";
