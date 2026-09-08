import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/state/session_provider.dart';

/// Client view of `users/{uid}`. Unlock is **read/listen only**.
@immutable
class UserDoc {
  const UserDoc({this.verifiedAt});

  final DateTime? verifiedAt;

  bool get isVerified => verifiedAt != null;
}

class UserDocNotifier extends Notifier<UserDoc> {
  @override
  UserDoc build() {
    ref.watch(sessionLoggedInTickProvider);
    // TODO(firebase): subscribe to users/{uid} snapshots (read only).
    // When verifiedAt appears, widgets watching [isVerifiedProvider]
    // rebuild in place — no forced screen refresh.
    return const UserDoc();
  }

  /// Simulate a user-doc snapshot after Admin/CF wrote `verifiedAt`.
  /// Not a Firestore write.
  void applySnapshot({DateTime? verifiedAt}) {
    state = UserDoc(verifiedAt: (verifiedAt ?? DateTime.now()).toUtc());
  }
}

final userDocProvider = NotifierProvider<UserDocNotifier, UserDoc>(
  UserDocNotifier.new,
);

final isVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(userDocProvider).isVerified;
});
