import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:petdate/firebase_options.dart';

@immutable
class AuthUser {
  const AuthUser({required this.uid, this.providerId});

  final String uid;
  final String? providerId;
}

sealed class AuthException implements Exception {
  const AuthException();
}

/// User dismissed the provider sheet. A01 should stay put with no error UI.
class AuthCancelled extends AuthException {
  const AuthCancelled();
}

/// Sign-in failed for any non-cancel reason. A01 shows a generic message.
class AuthFailure extends AuthException {
  const AuthFailure();
}

abstract class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithGoogle();

  Future<AuthUser> signInWithApple();

  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

/// Live Firebase user. Prefer [AppSession.uid] for simple reads; use this
/// stream when feature code needs provider changes without driving phases.
final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Reactive AuthUser. Watches [authStateChangesProvider] so widgets rebuild,
/// and always reads [AuthRepository.currentUser] as the source of truth.
final currentAuthUserProvider = Provider<AuthUser?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.read(authRepositoryProvider).currentUser;
});

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    this._auth,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInit;

  FirebaseAuth get _firebaseAuth {
    if (Firebase.apps.isEmpty) {
      throw const AuthFailure();
    }
    return _auth ?? FirebaseAuth.instance;
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      providerId: user.providerData.isEmpty
          ? null
          : user.providerData.first.providerId,
    );
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= _googleSignIn.initialize(
      // Populated after Google Sign-In is enabled and FlutterFire is re-run.
      clientId: DefaultFirebaseOptions.ios.iosClientId,
    );
  }

  Exception _mapFirebase(FirebaseAuthException error) {
    const cancelled = {
      'canceled',
      'cancelled',
      'web-context-cancelled',
      'ERROR_ABORTED_BY_USER',
    };
    if (cancelled.contains(error.code)) {
      return const AuthCancelled();
    }
    return const AuthFailure();
  }

  @override
  AuthUser? get currentUser {
    if (Firebase.apps.isEmpty) return null;
    return _mapUser((_auth ?? FirebaseAuth.instance).currentUser);
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    if (Firebase.apps.isEmpty) {
      return Stream<AuthUser?>.value(null);
    }
    return (_auth ?? FirebaseAuth.instance).authStateChanges().map(_mapUser);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure();
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _firebaseAuth.signInWithCredential(credential);
      final user = _mapUser(result.user);
      if (user == null) throw const AuthFailure();
      return user;
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelled();
      }
      throw const AuthFailure();
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    } on Object {
      throw const AuthFailure();
    }
  }

  @override
  Future<AuthUser> signInWithApple() async {
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      final result = await _firebaseAuth.signInWithProvider(provider);
      final user = _mapUser(result.user);
      if (user == null) throw const AuthFailure();
      return user;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebase(error);
    } on Object {
      throw const AuthFailure();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } on Object {
      // Google session may not exist (Apple-only, tests, unconfigured hosts).
    }
    if (Firebase.apps.isEmpty) return;
    await (_auth ?? FirebaseAuth.instance).signOut();
  }
}
