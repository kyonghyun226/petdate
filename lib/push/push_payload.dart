import 'package:flutter/foundation.dart';

/// FCM `data.type` values. Keep in sync with `functions/src/fcm.ts`.
enum PushKind {
  match,
  message,
  meetProposal;

  static const matchWire = 'match';
  static const messageWire = 'message';
  static const meetProposalWire = 'meet_proposal';

  String get wireValue => switch (this) {
    PushKind.match => matchWire,
    PushKind.message => messageWire,
    PushKind.meetProposal => meetProposalWire,
  };

  static PushKind? tryParse(String? raw) {
    return switch (raw) {
      matchWire => PushKind.match,
      messageWire => PushKind.message,
      meetProposalWire => PushKind.meetProposal,
      _ => null,
    };
  }
}

/// Client + Functions payload. All values are strings on the wire.
@immutable
class PushPayload {
  const PushPayload({required this.type, required this.threadId});

  final PushKind type;

  /// Same as `matches/{matchId}` / C02 [threadId].
  final String threadId;

  static const typeField = 'type';
  static const threadIdField = 'threadId';
  static const matchIdField = 'matchId';

  /// Infra contract (`functions/src/fcm.ts` `toFcmData`).
  Map<String, String> toData() => {
    typeField: type.wireValue,
    matchIdField: threadId,
  };

  /// Parses an FCM `data` map. Infra sends [matchIdField]; [threadIdField]
  /// is accepted as an alias.
  static PushPayload? tryParse(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return null;
    final type = PushKind.tryParse(data[typeField]?.toString());
    final threadId = (data[matchIdField] ?? data[threadIdField])?.toString();
    if (type == null || threadId == null || threadId.isEmpty) return null;
    return PushPayload(type: type, threadId: threadId);
  }
}
