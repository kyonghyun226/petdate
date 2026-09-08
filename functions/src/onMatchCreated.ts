import {onDocumentCreated} from "firebase-functions/firestore";
import {db, messaging} from "./firebase";
import {otherParticipantUids, PUSH_COPY, sendPushToUids} from "./fcm";

/**
 * Notify each match participant once when matches/{matchId} is created.
 *
 * P1 later — meetProposals/{proposalId} onCreate:
 *   load matches/{matchId}.userIds, exclude fromUid, fan-out with
 *   data { matchId, type: "meet_proposal" }.
 *   Safe copy example: title "반짝산책" /
 *   body "산책 약속 제안이 도착했어요".
 */
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
