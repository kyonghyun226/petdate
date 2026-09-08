import {onDocumentCreated} from "firebase-functions/firestore";
import {db, messaging} from "./firebase";
import {otherParticipantUids, PUSH_COPY, sendPushToUids} from "./fcm";

/** Notify each match participant once when matches/{matchId} is created. */
export const onMatchCreated = onDocumentCreated(
  "matches/{matchId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      return;
    }
    const matchId = event.params.matchId;
    const recipients = otherParticipantUids(snap.get("userIds"));
    if (recipients.length === 0) {
      return;
    }
    await sendPushToUids(
      db,
      messaging,
      recipients,
      PUSH_COPY.match,
      {matchId, type: "match"},
    );
  },
);
