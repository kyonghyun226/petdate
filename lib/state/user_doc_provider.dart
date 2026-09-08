import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/state/session_provider.dart';

/// Client view of `users/{uid}`. Unlock is **read / listen only**.
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
    // TODO(firebase): subscribe to users/{uid} (get + snapshots, read only).
    // isVerified flips when the remote doc contains verifiedAt.
    return const UserDoc();
  }

  /// Handle a remote user-doc snapshot. Not a Firestore write.
  void ingestListenSnapshot({DateTime? verifiedAt}) {
    state = UserDoc(verifiedAt: (verifiedAt ?? DateTime.now()).toUtc());
  }

  /// After CF succeeds, **read/listen** the user doc.
  /// Mock: emit the snapshot the server would have written.
  Future<void> pullRemoteUserDoc({required bool afterCallableSuccess}) async {
    if (!afterCallableSuccess) return;
    ingestListenSnapshot();
  }
}

final userDocProvider = NotifierProvider<UserDocNotifier, UserDoc>(
  UserDocNotifier.new,
);

/// Derived from the user-doc listen/get — never from a client write.
final isVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(userDocProvider).isVerified;
});
