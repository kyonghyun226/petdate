import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {HttpsError} from "firebase-functions/https";
import {callerUid} from "./caller";

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
