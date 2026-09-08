import type {DocumentReference, Firestore} from "firebase-admin/firestore";
import type {Messaging} from "firebase-admin/messaging";
import {logger} from "firebase-functions";

export const FCM_TOKENS_SUBCOLLECTION = "fcmTokens";
export const FCM_MULTICAST_LIMIT = 500;

export const STALE_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

export type PushDataType = "message" | "match";

export const PUSH_COPY = {
  message: {
    title: "반짝산책",
    body: "새 메시지가 도착했어요",
  },
  match: {
    title: "반짝산책",
    body: "산책 메이트와 연결됐어요",
  },
} as const;

/**
 * Unique match participants, optionally excluding the actor (sender /
 * proposer). Drops non-strings and empty ids.
 */
export function otherParticipantUids(
  userIds: unknown,
  excludeUid?: unknown,
): string[] {
  if (!Array.isArray(userIds)) {
    return [];
  }
  const seen = new Set<string>();
  const result: string[] = [];
  for (const uid of userIds) {
    if (typeof uid !== "string" || uid.length === 0) {
      continue;
    }
    if (excludeUid != null && uid === excludeUid) {
      continue;
    }
    if (seen.has(uid)) {
      continue;
    }
    seen.add(uid);
    result.push(uid);
  }
  return result;
}

export function isStaleTokenError(error: unknown): boolean {
  if (error == null || typeof error !== "object") {
    return false;
  }
  const code = "code" in error ? error.code : undefined;
  return typeof code === "string" && STALE_TOKEN_CODES.has(code);
}

export function chunkArray<T>(
  items: readonly T[],
  size = FCM_MULTICAST_LIMIT,
): T[][] {
  if (items.length === 0) {
    return [];
  }
  if (size <= 0) {
    return [items.slice()];
  }
  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

type LoadedToken = {
  ref: DocumentReference;
  token: string;
};

export async function loadRecipientTokens(
  db: Firestore,
  uids: readonly string[],
): Promise<LoadedToken[]> {
  const uniqueUids = [...new Set(uids.filter((uid) => uid.length > 0))];
  const snapshots = await Promise.all(
    uniqueUids.map((uid) =>
      db.collection("users").doc(uid).collection(FCM_TOKENS_SUBCOLLECTION).get(),
    ),
  );

  const seenTokens = new Set<string>();
  const result: LoadedToken[] = [];
  for (const snap of snapshots) {
    for (const doc of snap.docs) {
      const token = doc.get("token");
      if (typeof token !== "string" || token.length === 0) {
        continue;
      }
      if (seenTokens.has(token)) {
        continue;
      }
      seenTokens.add(token);
      result.push({ref: doc.ref, token});
    }
  }
  return result;
}

export type SendPushResult = {
  attempted: number;
  success: number;
  staleRemoved: number;
};

/**
 * Fan-out a notification + string data payload to every stored token
 * for the given uids. Stale FCM tokens are deleted; other send errors
 * are logged and ignored so a dead device does not retry the trigger.
 */
export async function sendPushToUids(
  db: Firestore,
  messaging: Pick<Messaging, "sendEachForMulticast">,
  uids: readonly string[],
  notification: {title: string; body: string},
  data: {matchId: string; type: PushDataType},
): Promise<SendPushResult> {
  const tokens = await loadRecipientTokens(db, uids);
  if (tokens.length === 0) {
    logger.info("fcm skip: no tokens", {
      uids,
      type: data.type,
      matchId: data.matchId,
    });
    return {attempted: 0, success: 0, staleRemoved: 0};
  }

  let success = 0;
  const staleRefs: DocumentReference[] = [];

  for (const batch of chunkArray(tokens)) {
    const response = await messaging.sendEachForMulticast({
      tokens: batch.map((item) => item.token),
      notification,
      data: {
        matchId: data.matchId,
        type: data.type,
      },
    });
    response.responses.forEach((item, index) => {
      if (item.success) {
        success += 1;
        return;
      }
      if (isStaleTokenError(item.error)) {
        staleRefs.push(batch[index].ref);
        return;
      }
      logger.warn("fcm send failed", {
        code: item.error?.code,
        matchId: data.matchId,
        type: data.type,
      });
    });
  }

  const deletes = await Promise.allSettled(
    staleRefs.map((ref) => ref.delete()),
  );
  const staleRemoved = deletes.filter((item) => item.status === "fulfilled")
    .length;
  if (staleRefs.length > 0) {
    logger.info("fcm removed stale tokens", {
      count: staleRemoved,
      matchId: data.matchId,
      type: data.type,
    });
  }

  return {
    attempted: tokens.length,
    success,
    staleRemoved,
  };
}
