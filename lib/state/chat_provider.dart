import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
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
}

class ChatNotifier extends Notifier<ChatState> {
  int _msgSeq = 0;

  @override
  ChatState build() {
    ref.watch(sessionLoggedInTickProvider);
    _msgSeq = 0;
    return const ChatState();
  }

  ChatThread ensureMatchThread(DiscoveryProfile profile) {
    final existing = state.byProfile(profile.id);
    if (existing != null) return existing;

    final messages = <ChatMessage>[
      ChatMessage(
        id: _nextId(),
        text: AppCopy.chatSystemMatch,
        isMine: false,
        kind: ChatMessageKind.system,
      ),
      if (profile.likedMe)
        ChatMessage(
          id: _nextId(),
          text: '만남 제안 · 공원 · 주말 아침',
          isMine: false,
          kind: ChatMessageKind.meetup,
          receipt: MeetupReceipt.pending,
        ),
    ];
    final thread = ChatThread(
      id: 'chat_${profile.id}',
      profile: profile,
      messages: messages,
    );
    state = ChatState(threads: [...state.threads, thread]);
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
  }

  void sendMeetup(String threadId, MeetupProposal proposal) {
    final place = MeetupPlaceCopy.label(proposal.place);
    final detail = proposal.place == MeetupPlace.other &&
            proposal.placeDetail.trim().isNotEmpty
        ? '${proposal.placeDetail.trim()} · $place'
        : place;
    final memo = proposal.memo.trim();
    final text = memo.isEmpty
        ? '만남 제안 · $detail · ${proposal.timeLabel}'
        : '만남 제안 · $detail · ${proposal.timeLabel}\n$memo';
    _append(
      threadId,
      ChatMessage(
        id: _nextId(),
        text: text,
        isMine: true,
        kind: ChatMessageKind.meetup,
      ),
    );
  }

  void _append(String threadId, ChatMessage message) {
    state = ChatState(
      threads: [
        for (final t in state.threads)
          if (t.id == threadId)
            t.copyWith(messages: [...t.messages, message])
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
