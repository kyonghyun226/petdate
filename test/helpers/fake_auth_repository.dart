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
  Stream<AuthUser?> authStateChanges() async* {
    yield signedInUser;
    yield* _controller.stream;
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

  @override
  Future<void> deleteAccount() async {
    signedInUser = null;
    _controller.add(null);
  }
}
