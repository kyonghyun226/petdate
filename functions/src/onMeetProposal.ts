import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/firestore";
import {logger} from "firebase-functions";
import {db, messaging} from "./firebase";
import {
  otherParticipantUids,
  PUSH_COPY,
  sendPushToUids,
  shouldNotifyMeetProposalUpdate,
} from "./fcm";

function proposalCopy(status: string): {title: string; body: string} {
  if (status === "accepted") {
    return PUSH_COPY.meetAccepted;
  }
  if (status === "counter") {
    return PUSH_COPY.meetCounter;
  }
  return PUSH_COPY.meetProposal;
}

/**
 * Notify the other match member when a walk meetup is proposed.
 * Excludes fromUid. data: type meet_proposal, matchId, proposalId.
 */
export const onMeetProposalCreated = onDocumentCreated(
  "meetProposals/{proposalId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      return;
    }
    const proposalId = event.params.proposalId;
    const matchId = snap.get("matchId");
    const fromUid = snap.get("fromUid");
    if (typeof matchId !== "string" || matchId.length === 0) {
      logger.warn("onMeetProposalCreated: matchId missing", {proposalId});
      return;
    }
    const match = await db.collection("matches").doc(matchId).get();
    if (!match.exists) {
      logger.warn("onMeetProposalCreated: match missing", {matchId, proposalId});
      return;
    }
    const recipients = otherParticipantUids(match.get("userIds"), fromUid);
    if (recipients.length === 0) {
      return;
    }
    await sendPushToUids(
      db,
      messaging,
      recipients,
      PUSH_COPY.meetProposal,
      {matchId, type: "meet_proposal", proposalId},
    );
  },
);

/**
 * Notify the proposer (fromUid) when the other member accepts or counters.
 * Dismissed (and unchanged status) is skipped.
 * data: type meet_proposal, matchId, proposalId, status.
 */
export const onMeetProposalUpdated = onDocumentUpdated(
  "meetProposals/{proposalId}",
  async (event) => {
    const change = event.data;
    if (!change) {
      return;
    }
    const before = change.before.get("status");
    const after = change.after.get("status");
    if (!shouldNotifyMeetProposalUpdate(before, after)) {
      return;
    }
    const proposalId = event.params.proposalId;
    const matchId = change.after.get("matchId");
    const fromUid = change.after.get("fromUid");
    if (typeof matchId !== "string" || matchId.length === 0) {
      return;
    }
    if (typeof fromUid !== "string" || fromUid.length === 0) {
      return;
    }
    await sendPushToUids(
      db,
      messaging,
      [fromUid],
      proposalCopy(after),
      {matchId, type: "meet_proposal", proposalId, status: after},
    );
  },
);
