import 'dart:async';

import 'package:petdate/auth/auth_repository.dart';

enum FakeAuthOutcome { success, cancelled, failure }

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.signedInUser, this.outcome = FakeAuthOutcome.success});

  AuthUser? signedInUser;
  FakeAuthOutcome outcome;

  final _controller = StreamController<AuthUser?>.broadcast();

  AuthUser _succeed(String providerId) {
    final user = AuthUser(uid: 'fake-$providerId', providerId: providerId);
    signedInUser = user;
    _controller.add(user);
    return user;
  }

  Future<AuthUser> _complete(String providerId) async {
    switch (outcome) {
      case FakeAuthOutcome.cancelled:
        throw const AuthCancelled();
      case FakeAuthOutcome.failure:
        throw const AuthFailure();
      case FakeAuthOutcome.success:
        return _succeed(providerId);
    }
  }

  @override
  AuthUser? get currentUser => signedInUser;

  @override
  Stream<AuthUser?> authStateChanges() {
    return Stream<AuthUser?>.multi((listener) {
      listener.add(signedInUser);
      final sub = _controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = () async {
          await sub.cancel();
        };
    });
  }

  @override
  Future<AuthUser> signInWithGoogle() => _complete('google.com');

  @override
  Future<AuthUser> signInWithApple() => _complete('apple.com');

  @override
  Future<void> signOut() async {
    signedInUser = null;
    _controller.add(null);
  }
}
