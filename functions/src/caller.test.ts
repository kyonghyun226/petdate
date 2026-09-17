import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {HttpsError} from "firebase-functions/https";
import {callerUid, requirePhoneNumber} from "./caller";

describe("callerUid", () => {
  it("requires a signed-in caller", () => {
    assert.throws(
      () => callerUid(undefined, undefined),
      (err: unknown) =>
        err instanceof HttpsError && err.code === "unauthenticated",
    );
  });

  it("uses auth uid and ignores a matching requested uid", () => {
    assert.equal(callerUid("alice", "alice"), "alice");
    assert.equal(callerUid("alice", undefined), "alice");
    assert.equal(callerUid("alice", ""), "alice");
  });

  it("denies setting another user's verifiedAt", () => {
    assert.throws(
      () => callerUid("alice", "bob"),
      (err: unknown) =>
        err instanceof HttpsError && err.code === "permission-denied",
    );
  });
});

describe("requirePhoneNumber", () => {
  it("requires a non-empty phone_number claim", () => {
    assert.throws(
      () => requirePhoneNumber(undefined),
      (err: unknown) =>
        err instanceof HttpsError && err.code === "failed-precondition",
    );
    assert.throws(
      () => requirePhoneNumber(""),
      (err: unknown) =>
        err instanceof HttpsError && err.code === "failed-precondition",
    );
    assert.throws(
      () => requirePhoneNumber("   "),
      (err: unknown) =>
        err instanceof HttpsError && err.code === "failed-precondition",
    );
  });

  it("returns the phone number when present", () => {
    assert.equal(requirePhoneNumber("+821012345678"), "+821012345678");
  });
});
