import 'package:flutter/foundation.dart';
import 'package:petdate/models/discovery_profile.dart';

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
  });

  final String id;
  final DiscoveryProfile profile;
  final List<ChatMessage> messages;

  int get outboundCount =>
      messages.where((m) => m.isMine && m.kind != ChatMessageKind.system).length;

  String get preview {
    if (messages.isEmpty) return '';
    return messages.last.text;
  }

  ChatThread copyWith({List<ChatMessage>? messages}) {
    return ChatThread(
      id: id,
      profile: profile,
      messages: messages ?? this.messages,
    );
  }
}

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
