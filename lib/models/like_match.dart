import 'package:flutter/foundation.dart';

@immutable
class LikeRecord {
  const LikeRecord({
    required this.id,
    required this.fromUid,
    required this.toPetId,
    required this.toOwnerId,
  });

  final String id;
  final String fromUid;
  final String toPetId;
  final String toOwnerId;
}

@immutable
class MatchRecord {
  const MatchRecord({
    required this.id,
    required this.userIds,
    required this.petIds,
  });

  final String id;
  final List<String> userIds;
  final List<String> petIds;

  String otherUid(String myUid) {
    for (final id in userIds) {
      if (id != myUid) return id;
    }
    return myUid;
  }
}
