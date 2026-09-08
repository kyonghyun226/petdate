import 'package:flutter/foundation.dart';
import 'package:petdate/models/discovery_profile.dart';

enum ChatMessageKind { text, system, meetup }

enum MeetupPlace { park, petCafe, other }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    this.kind = ChatMessageKind.text,
  });

  final String id;
  final String text;
  final bool isMine;
  final ChatMessageKind kind;
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
}
