import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/backend_mode.dart';
import 'package:petdate/data/mock_social_repository.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/firebase/firestore_ids.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/session_provider.dart';

@immutable
class ChatState {
  const ChatState({this.threads = const []});

  final List<ChatThread> threads;

  ChatThread? byId(String id) {
    for (final t in threads) {
      if (t.id == id) return t;
    }
    return null;
  }

  ChatThread? byProfile(String profileId) {
    for (final t in threads) {
      if (t.profile.id == profileId) return t;
    }
    return null;
  }

  List<ChatThread> visible(Set<String> blockedIds, {String? myUid}) {
    final rows = [
      for (final t in threads)
        if (!blockedIds.contains(t.profile.id) &&
            !t.unavailable &&
            t.isParticipant(myUid))
          t,
    ];
    rows.sort((a, b) => b.sortAt.compareTo(a.sortAt));
    return rows;
  }
}

class ChatNotifier extends Notifier<ChatState> {
  static const _inboundDemoProposal = MeetupProposal(
    place: MeetupPlace.park,
    placeDetail: '',
    timeLabel: AppCopy.meetupTonight,
    memo: '',
  );

  int _msgSeq = 0;

  @override
  ChatState build() {
    ref.watch(sessionLoggedInTickProvider);
    _msgSeq = 0;
    if (ref.watch(useMockDataProvider)) {
      return const ChatState();
    }

    final uid = ref.watch(sessionProvider.select((s) => s.uid));
    if (uid == null) return const ChatState();
    final sub =
        ref.read(socialRepositoryProvider).watchThreads(myUid: uid).listen(
      _applyRemote,
    );
    ref.onDispose(sub.cancel);
    return const ChatState();
  }

  /// Test helper to drive empty / unread / navigation without Firestore.
  void replaceForTest({required List<ChatThread> threads}) {
    state = ChatState(threads: threads);
  }

  void markRead(String threadId) {
    var changed = false;
    final next = <ChatThread>[];
    for (final t in state.threads) {
      if (t.id == threadId && t.unread) {
        next.add(t.copyWith(unread: false));
        changed = true;
      } else {
        next.add(t);
      }
    }
    if (changed) state = ChatState(threads: next);
  }

  void _applyRemote(List<ChatThread> remote) {
    final prev = {for (final t in state.threads) t.id: t};
    final seen = <String>{};
    final next = <ChatThread>[];
    for (final incoming in remote) {
      seen.add(incoming.id);
      next.add(_mergeThread(prev[incoming.id], incoming));
    }
    for (final local in state.threads) {
      if (!seen.contains(local.id)) next.add(local);
    }
    state = ChatState(threads: next);
  }

  ChatThread _mergeThread(ChatThread? prev, ChatThread incoming) {
    if (prev == null) return incoming;
    final newActivity = prev.messages.length != incoming.messages.length ||
        (prev.messages.isNotEmpty &&
            incoming.messages.isNotEmpty &&
            prev.messages.last.id != incoming.messages.last.id);
    if (!prev.unread) {
      return incoming.copyWith(unread: newActivity && incoming.unread);
    }
    return incoming;
  }

  ChatThread ensureMatchThread(DiscoveryProfile profile) {
    final existing = state.byProfile(profile.id);
    if (existing != null) return existing;

    final uid = ref.read(sessionProvider).uid ?? 'local';
    final id = FirestoreIds.matchId(uid, profile.id);
    final byId = state.byId(id);
    if (byId != null) return byId;

    final messages = <ChatMessage>[
      ChatMessage(
        id: 'sys_$id',
        text: AppCopy.chatSystemMatch,
        isMine: false,
        kind: ChatMessageKind.system,
      ),
      if (profile.likedMe)
        ChatMessage(
          id: _nextId(),
          text: MeetupCopy.cardText(_inboundDemoProposal),
          isMine: false,
          kind: ChatMessageKind.meetup,
          receipt: MeetupReceipt.pending,
          proposal: _inboundDemoProposal,
        ),
    ];
    final unread = messages.any(
      (m) => !m.isMine && m.kind != ChatMessageKind.system,
    );
    final thread = ChatThread(
      id: id,
      profile: profile,
      messages: messages,
      updatedAt: DateTime.now(),
      unread: unread,
      participantIds: {uid, profile.id},
    );
    state = ChatState(threads: [...state.threads, thread]);
    final repo = ref.read(socialRepositoryProvider);
    if (ref.read(useMockDataProvider) && repo is MockSocialRepository) {
      repo.ensureThread(
        uid,
        profile,
        messages: messages,
        unread: unread,
        updatedAt: thread.updatedAt,
      );
    }
    return thread;
  }

  void setMeetupReceipt(
    String threadId,
    String messageId,
    MeetupReceipt receipt,
  ) {
    state = ChatState(
      threads: [
        for (final t in state.threads)
          if (t.id == threadId)
            t.copyWith(
              messages: [
                for (final m in t.messages)
                  if (m.id == messageId) m.copyWith(receipt: receipt) else m,
              ],
            )
          else
            t,
      ],
    );
    unawaited(
      ref.read(socialRepositoryProvider).setMeetupStatus(
            proposalId: messageId,
            receipt: receipt,
          ),
    );
  }

  void sendText(String threadId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _append(
      threadId,
      ChatMessage(
        id: _nextId(),
        text: trimmed,
        isMine: true,
      ),
    );
    final uid = ref.read(sessionProvider).uid;
    if (uid == null) return;
    unawaited(
      ref.read(socialRepositoryProvider).sendText(
            matchId: threadId,
            senderId: uid,
            text: trimmed,
          ),
    );
  }

  void sendMeetup(String threadId, MeetupProposal proposal) {
    _append(
      threadId,
      ChatMessage(
        id: _nextId(),
        text: MeetupCopy.cardText(proposal),
        isMine: true,
        kind: ChatMessageKind.meetup,
        proposal: proposal,
      ),
    );
    final uid = ref.read(sessionProvider).uid;
    if (uid == null) return;
    unawaited(
      ref.read(socialRepositoryProvider).sendMeetup(
            matchId: threadId,
            fromUid: uid,
            proposal: proposal,
          ),
    );
  }

  void removeByProfile(String profileId) {
    state = ChatState(
      threads: [
        for (final t in state.threads)
          if (t.profile.id != profileId) t,
      ],
    );
  }

  void _append(String threadId, ChatMessage message) {
    state = ChatState(
      threads: [
        for (final t in state.threads)
          if (t.id == threadId)
            t.copyWith(
              messages: [...t.messages, message],
              updatedAt: DateTime.now(),
              unread: false,
            )
          else
            t,
      ],
    );
  }

  String _nextId() => 'msg_${_msgSeq++}';
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
