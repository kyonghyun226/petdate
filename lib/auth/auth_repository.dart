import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:petdate/firebase/account_deletion.dart';
import 'package:petdate/firebase_options.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

@immutable
class AuthUser {
  const AuthUser({required this.uid, this.providerId, this.email});

  final String uid;
  final String? providerId;

  /// Primary Auth email when available (Google / Apple). Used for review-demo
  /// allowlisting; may be null for some Apple Hide My Email sessions.
  final String? email;
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

  /// Permanently delete the signed-in account and associated data.
  Future<void> deleteAccount();
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
    String? email = user.email;
    if (email == null || email.isEmpty) {
      for (final info in user.providerData) {
        final candidate = info.email;
        if (candidate != null && candidate.isNotEmpty) {
          email = candidate;
          break;
        }
      }
    }
    return AuthUser(
      uid: user.uid,
      providerId: user.providerData.isEmpty
          ? null
          : user.providerData.first.providerId,
      email: email,
    );
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= _googleSignIn.initialize(
      // iOS OAuth client only — passing it on Android breaks native Google Sign-In.
      clientId: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
      // Web client (type 3). Needed on Android for a Firebase-usable idToken.
      serverClientId: DefaultFirebaseOptions.googleServerClientId,
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
    assert(() {
      debugPrint(
        'FirebaseAuthException ${error.code}: ${error.message}',
      );
      return true;
    }());
    return const AuthFailure();
  }

  Exception _mapObject(Object error) {
    if (error is AuthException) return error;
    if (error is FirebaseAuthException) return _mapFirebase(error);
    if (error is SignInWithAppleAuthorizationException) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const AuthCancelled();
      }
      assert(() {
        debugPrint(
          'SignInWithAppleAuthorizationException ${error.code}: $error',
        );
        return true;
      }());
      return const AuthFailure();
    }
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('cancel') ||
          code == '1001' ||
          error.message?.toLowerCase().contains('cancel') == true) {
        return const AuthCancelled();
      }
      assert(() {
        debugPrint('PlatformException ${error.code}: ${error.message}');
        return true;
      }());
      return const AuthFailure();
    }
    assert(() {
      debugPrint('Auth unexpected error: $error');
      return true;
    }());
    return const AuthFailure();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Native Apple ID sheet + Firebase credential (iOS / macOS).
  /// Prefer this over [signInWithProvider] — more reliable with nonce +
  /// authorizationCode on current firebase_auth builds.
  Future<AuthUser> _signInWithAppleNative() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    final idToken = apple.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthFailure();
    }
    final credential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
    );
    final result = await _firebaseAuth.signInWithCredential(credential);
    final user = _mapUser(result.user);
    if (user == null) throw const AuthFailure();
    return user;
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
    } on Object catch (error) {
      throw _mapObject(error);
    }
  }

  @override
  Future<AuthUser> signInWithApple() async {
    try {
      final useNativeSheet = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);
      if (useNativeSheet) {
        return await _signInWithAppleNative();
      }
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      final result = await _firebaseAuth.signInWithProvider(provider);
      final user = _mapUser(result.user);
      if (user == null) throw const AuthFailure();
      return user;
    } on AuthException {
      rethrow;
    } on Object catch (error) {
      throw _mapObject(error);
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

  @override
  Future<void> deleteAccount() async {
    final ok = await AccountDeletion.deleteCurrentAccount();
    if (!ok) throw const AuthFailure();
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } on Object {
      // Best-effort local Google session clear after Auth wipe.
    }
  }
}
