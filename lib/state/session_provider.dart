import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/data/demo_mode.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/session_bootstrap.dart';
import 'package:petdate/push/fcm_token_store.dart';
import 'package:petdate/push/push_providers.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';

enum AppPhase { splash, onboarding, login, profile, main }

enum MainTab { home, spark, chat, meongstar }

@immutable
class AppSession {
  const AppSession({
    this.phase = AppPhase.splash,
    this.isLoggedIn = false,
    this.onboardingCompleted = false,
    this.profileCompleted = false,
    this.mainTab = MainTab.home,
    this.uid,
  });

  final AppPhase phase;
  final bool isLoggedIn;
  final bool onboardingCompleted;
  final bool profileCompleted;
  final MainTab mainTab;

  /// Firebase Auth uid when signed in. Feature code can watch this without
  /// touching navigation.
  final String? uid;

  bool get showBottomNav => phase == AppPhase.main && isLoggedIn;

  AppSession copyWith({
    AppPhase? phase,
    bool? isLoggedIn,
    bool? onboardingCompleted,
    bool? profileCompleted,
    MainTab? mainTab,
    String? uid,
    bool clearUid = false,
  }) {
    return AppSession(
      phase: phase ?? this.phase,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      mainTab: mainTab ?? this.mainTab,
      uid: clearUid ? null : (uid ?? this.uid),
    );
  }
}

/// Owns splash → onboarding → login → profile → main.
///
/// Feature screens should read auth here, not replace this machine:
/// - [AppSession.uid] / [AppSession.isLoggedIn]
/// - [authStateChangesProvider] / [currentAuthUserProvider]
class SessionNotifier extends Notifier<AppSession> {
  @override
  AppSession build() => const AppSession();

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  /// After splash: a persisted Firebase user skips login (and onboarding),
  /// but still hits the profile gate until that flag is set.
  ///
  /// [remoteProfileCompleted] comes from a **successful** Firestore read
  /// that found `pets/{uid}`. Failed loads must pass false so we do not
  /// invent a completed profile.
  void completeSplash({
    bool remoteProfileCompleted = false,
  }) {
    final user = _auth.currentUser;
    if (user != null) {
      final profileCompleted =
          remoteProfileCompleted || state.profileCompleted;
      state = state.copyWith(
        isLoggedIn: true,
        onboardingCompleted: true,
        uid: user.uid,
        profileCompleted: profileCompleted,
        phase: profileCompleted ? AppPhase.main : AppPhase.profile,
      );
      return;
    }
    state = state.copyWith(phase: AppPhase.onboarding);
  }

  void completeOnboarding() {
    state = state.copyWith(
      onboardingCompleted: true,
      phase: AppPhase.login,
    );
  }

  void goToLogin() {
    state = state.copyWith(
      onboardingCompleted: true,
      phase: AppPhase.login,
    );
  }

  /// Session update after a successful provider sign-in. Tests can call this
  /// directly to skip the Google/Apple sheets.
  ///
  /// Returning users with `pets/{uid}` skip the profile wizard and land in
  /// main (same gate as splash). Likes stay locked until [UserDoc] listen
  /// sees `verifiedAt`.
  Future<void> completeLogin() async {
    final uid = _auth.currentUser?.uid;
    state = state.copyWith(
      isLoggedIn: true,
      onboardingCompleted: true,
      uid: uid,
    );

    RemoteSessionSnapshot? remote;
    try {
      remote = await SessionBootstrap.load();
      if (remote != null && !remote.loadFailed) {
        _hydrateRemote(remote);
      }
    } on Object catch (error) {
      assert(() {
        debugPrint('SessionBootstrap after login failed: $error');
        return true;
      }());
    }

    // Skip wizard only when Firestore successfully returned a pet.
    // loadFailed / null → profile gate (do not fake "completed").
    final hasRemotePet = remote != null && !remote.loadFailed && remote.pet != null;
    final profileCompleted = hasRemotePet || state.profileCompleted;
    state = state.copyWith(
      profileCompleted: profileCompleted,
      phase: profileCompleted ? AppPhase.main : AppPhase.profile,
      mainTab: profileCompleted ? MainTab.home : state.mainTab,
    );
    unawaited(
      IdentityVerification.ensureUserDocExists(uid: state.uid),
    );
  }

  void _hydrateRemote(RemoteSessionSnapshot? remote) {
    if (remote == null) return;
    if (remote.pet != null) {
      ref.read(profileDraftProvider.notifier).hydrate(remote.pet!);
    }
    if (remote.verifiedAt != null) {
      ref.read(userDocProvider.notifier).applyRemoteSnapshot(
            verifiedAt: remote.verifiedAt,
          );
    }
  }

  Future<void> signInWithGoogle() async {
    await _auth.signInWithGoogle();
    await completeLogin();
  }

  Future<void> signInWithApple() async {
    await _auth.signInWithApple();
    await completeLogin();
  }

  /// Private-test / review path: enter main with MockCatalog, no Auth.
  ///
  /// Caller should hydrate [profileDraftProvider] + verified user-doc first
  /// (avoids a Riverpod cycle with ProfileDraftNotifier → session tick).
  void enterGuestPreview() {
    state = state.copyWith(
      isLoggedIn: true,
      onboardingCompleted: true,
      profileCompleted: true,
      uid: DemoMode.uid,
      phase: AppPhase.main,
      mainTab: MainTab.home,
    );
  }

  void backFromProfile() {
    state = state.copyWith(phase: AppPhase.login);
  }

  void completeProfile() {
    state = state.copyWith(
      profileCompleted: true,
      phase: AppPhase.main,
      mainTab: MainTab.home,
    );
  }

  void selectTab(MainTab tab) {
    state = state.copyWith(mainTab: tab);
  }

  void logout() {
    state = const AppSession(
      phase: AppPhase.login,
      onboardingCompleted: true,
    );
  }

  Future<void> signOut() async {
    await FcmTokenRemote.deleteOwnTokens();
    await _auth.signOut();
    // Clear pushed routes (마이 등) so SessionGate login is visible.
    ref.read(rootNavigatorKeyProvider).currentState?.popUntil(
          (route) => route.isFirst,
        );
    logout();
  }

  /// App Store account deletion. Wipes remote data when Auth is live.
  Future<void> deleteAccount() async {
    await _auth.deleteAccount();
    ref.read(rootNavigatorKeyProvider).currentState?.popUntil(
          (route) => route.isFirst,
        );
    logout();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, AppSession>(
  SessionNotifier.new,
);

/// Bumps mock stores when the user logs out.
final sessionLoggedInTickProvider = Provider<int>((ref) {
  final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
  return loggedIn ? 1 : 0;
});
