import {HttpsError} from "firebase-functions/https";

/**
 * Resolves the only uid allowed to receive verifiedAt: the signed-in caller.
 * A client-supplied uid is ignored unless it mismatches — then we deny.
 */
export function callerUid(
  authUid: string | undefined,
  requestedUid: unknown,
): string {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  if (
    requestedUid != null &&
    requestedUid !== "" &&
    requestedUid !== authUid
  ) {
    throw new HttpsError(
      "permission-denied",
      "Cannot set verifiedAt for another user.",
    );
  }
  return authUid;
}

/**
 * A02 requires Firebase Phone Auth linked to the caller.
 * ID tokens expose `phone_number` after SMS verification + link.
 */
export function requirePhoneNumber(phoneNumber: unknown): string {
  if (typeof phoneNumber !== "string" || phoneNumber.trim() === "") {
    throw new HttpsError(
      "failed-precondition",
      "Phone verification required before markUserVerified.",
    );
  }
  return phoneNumber;
}
