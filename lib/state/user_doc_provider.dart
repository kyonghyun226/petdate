import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/firebase/identity_remote.dart';
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
  StreamSubscription<RemoteUserSnapshot>? _remote;

  /// Remote user-doc stream (Firestore when Auth is live; mock otherwise).
  Stream<UserDoc> get snapshots =>
      _snapshots?.stream ?? const Stream.empty();

  @override
  UserDoc build() {
    ref.watch(sessionLoggedInTickProvider);
    final controller = StreamController<UserDoc>.broadcast();
    _snapshots = controller;
    _remote?.cancel();
    _remote = IdentityRemote.watchCurrentUserDoc()?.listen((remote) {
      applyRemoteSnapshot(verifiedAt: remote.verifiedAt);
    });
    ref.onDispose(() {
      _remote?.cancel();
      _remote = null;
      controller.close();
      if (identical(_snapshots, controller)) _snapshots = null;
    });
    return const UserDoc();
  }

  /// Apply a user-doc snapshot as-is. Missing `verifiedAt` stays unverified.
  void applyRemoteSnapshot({DateTime? verifiedAt}) {
    final next = UserDoc(verifiedAt: verifiedAt?.toUtc());
    state = next;
    final controller = _snapshots;
    if (controller != null && !controller.isClosed) {
      controller.add(next);
    }
  }

  /// Handle a remote user-doc snapshot that already has `verifiedAt`.
  /// Used by tests and the mock callable path. Not a Firestore write.
  /// Updates [userDocProvider] in place so H01/D01 rebuild the same CTA slot.
  void ingestListenSnapshot({DateTime? verifiedAt}) {
    applyRemoteSnapshot(verifiedAt: verifiedAt ?? DateTime.now());
  }

  /// After CF succeeds, **read/listen** the user doc.
  /// Live Auth: one-shot get. Mock: emit the snapshot the server would write.
  Future<void> pullRemoteUserDoc({
    required bool afterCallableSuccess,
    String? verifiedAtIso,
  }) async {
    if (!afterCallableSuccess) return;
    if (IdentityRemote.isLiveAuthReady) {
      final remote = await IdentityRemote.readCurrentUserDoc();
      if (remote != null && remote.verifiedAt != null) {
        applyRemoteSnapshot(verifiedAt: remote.verifiedAt);
        return;
      }
    }
    final parsed =
        verifiedAtIso == null ? null : DateTime.tryParse(verifiedAtIso);
    ingestListenSnapshot(verifiedAt: parsed);
  }
}

final userDocProvider = NotifierProvider<UserDocNotifier, UserDoc>(
  UserDocNotifier.new,
);

/// Derived from the user-doc listen/get — never from a client write.
final isVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(userDocProvider).isVerified;
});
