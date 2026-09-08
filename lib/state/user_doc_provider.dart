import 'dart:async';

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
  StreamController<UserDoc>? _snapshots;

  /// Remote user-doc stream (mock until Firestore snapshots are wired).
  Stream<UserDoc> get snapshots =>
      _snapshots?.stream ?? const Stream.empty();

  @override
  UserDoc build() {
    ref.watch(sessionLoggedInTickProvider);
    final controller = StreamController<UserDoc>.broadcast();
    _snapshots = controller;
    ref.onDispose(() {
      controller.close();
      if (identical(_snapshots, controller)) _snapshots = null;
    });
    // TODO(firebase): pipe users/{uid} snapshots into [_snapshots] (read only).
    return const UserDoc();
  }

  /// Handle a remote user-doc snapshot. Not a Firestore write.
  /// Updates [userDocProvider] in place so H01/D01 rebuild the same CTA slot.
  void ingestListenSnapshot({DateTime? verifiedAt}) {
    final next = UserDoc(verifiedAt: (verifiedAt ?? DateTime.now()).toUtc());
    state = next;
    final controller = _snapshots;
    if (controller != null && !controller.isClosed) {
      controller.add(next);
    }
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
