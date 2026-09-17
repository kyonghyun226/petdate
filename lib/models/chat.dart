import 'package:flutter/foundation.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/spark.dart';

enum ChatMessageKind { text, system, meetup }

enum MeetupPlace { park, petCafe, other }

enum MeetupReceipt { pending, accepted, countered, ignored }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    this.kind = ChatMessageKind.text,
    this.receipt,
    this.proposal,
  });

  final String id;
  final String text;
  final bool isMine;
  final ChatMessageKind kind;
  final MeetupReceipt? receipt;
  final MeetupProposal? proposal;

  ChatMessage copyWith({
    MeetupReceipt? receipt,
    MeetupProposal? proposal,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      isMine: isMine,
      kind: kind,
      receipt: receipt ?? this.receipt,
      proposal: proposal ?? this.proposal,
    );
  }
}

@immutable
class MeetupProposal {
  const MeetupProposal({
    required this.place,
    required this.placeDetail,
    required this.timeLabel,
    required this.memo,
  });

  final MeetupPlace place;
  final String placeDetail;
  final String timeLabel;
  final String memo;
}

@immutable
class ChatThread {
  const ChatThread({
    required this.id,
    required this.profile,
    required this.messages,
    this.updatedAt,
    this.unread = false,
    this.participantIds = const {},
    this.unavailable = false,
    this.opened = false,
  });

  final String id;
  final DiscoveryProfile profile;
  final List<ChatMessage> messages;
  final DateTime? updatedAt;
  final bool unread;

  /// Match members. Empty means "treat as a participant" for local mocks.
  final Set<String> participantIds;

  /// Counterpart withdrew or their pet doc is gone. C01 hides these rooms.
  final bool unavailable;

  /// True once the local user has opened C02 for this match.
  final bool opened;

  int get outboundCount =>
      messages.where((m) => m.isMine && m.kind != ChatMessageKind.system).length;

  bool get conversationStarted =>
      opened ||
      messages.any(
        (m) =>
            m.kind == ChatMessageKind.text ||
            (m.kind == ChatMessageKind.meetup && m.isMine),
      );

  DateTime get sortAt => updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  bool isParticipant(String? uid) {
    if (uid == null || participantIds.isEmpty) return true;
    return participantIds.contains(uid);
  }

  String get preview {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].kind != ChatMessageKind.system) {
        return messages[i].text;
      }
    }
    if (messages.isEmpty) return '';
    return messages.last.text;
  }

  String timeLabel({DateTime? now}) =>
      formatChatTime(updatedAt ?? DateTime.now(), now: now);

  ChatThread copyWith({
    List<ChatMessage>? messages,
    DateTime? updatedAt,
    bool? unread,
    Set<String>? participantIds,
    bool? unavailable,
    bool? opened,
  }) {
    return ChatThread(
      id: id,
      profile: profile,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      unread: unread ?? this.unread,
      participantIds: participantIds ?? this.participantIds,
      unavailable: unavailable ?? this.unavailable,
      opened: opened ?? this.opened,
    );
  }
}

String formatChatTime(DateTime at, {DateTime? now}) =>
    formatSparkRelativeTime(at, now: now);

abstract final class MeetupPlaceCopy {
  static String label(MeetupPlace place) => switch (place) {
        MeetupPlace.park => '공원',
        MeetupPlace.petCafe => '펫카페',
        MeetupPlace.other => '기타',
      };

  static MeetupPlace fromType(String? type) => switch (type) {
        'petCafe' => MeetupPlace.petCafe,
        'other' => MeetupPlace.other,
        _ => MeetupPlace.park,
      };
}

abstract final class MeetupCopy {
  static String cardText(MeetupProposal proposal) {
    final place = MeetupPlaceCopy.label(proposal.place);
    final detail = proposal.place == MeetupPlace.other &&
            proposal.placeDetail.trim().isNotEmpty
        ? '${proposal.placeDetail.trim()} · $place'
        : place;
    final memo = proposal.memo.trim();
    return memo.isEmpty
        ? '만남 제안 · $detail · ${proposal.timeLabel}'
        : '만남 제안 · $detail · ${proposal.timeLabel}\n$memo';
  }

  static String placeLine(MeetupProposal proposal) {
    if (proposal.place == MeetupPlace.other &&
        proposal.placeDetail.trim().isNotEmpty) {
      return proposal.placeDetail.trim();
    }
    return MeetupPlaceCopy.label(proposal.place);
  }
}
