import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions";
import {onCall} from "firebase-functions/https";
import {callerUid} from "./caller";
import {setVerifiedAtForUid} from "./verifiedAt";

initializeApp();

// Seoul — keep callables next to the intended Firestore region.
setGlobalOptions({
  region: "asia-northeast3",
  maxInstances: 10,
});

const db = getFirestore();

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
