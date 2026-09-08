import {onDocumentCreated} from "firebase-functions/firestore";
import {logger} from "firebase-functions";
import {db, messaging} from "./firebase";
import {otherParticipantUids, PUSH_COPY, sendPushToUids} from "./fcm";

/**
 * Notify the other match participant(s) when a chat message is created.
 * Excludes the sender. Body is generic — never echoes message text.
 */
export const onMessageCreated = onDocumentCreated(
  "threads/{matchId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      return;
    }
    const matchId = event.params.matchId;
    const senderId = snap.get("senderId");
    const match = await db.collection("matches").doc(matchId).get();
    if (!match.exists) {
      logger.warn("onMessageCreated: match missing", {matchId});
      return;
    }
    const recipients = otherParticipantUids(match.get("userIds"), senderId);
    if (recipients.length === 0) {
      return;
    }
    await sendPushToUids(
      db,
      messaging,
      recipients,
      PUSH_COPY.message,
      {matchId, type: "message"},
    );
  },
);
