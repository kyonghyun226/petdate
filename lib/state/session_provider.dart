import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';

enum AppPhase { splash, onboarding, login, goal, profile, main }

enum MainTab { home, spark, chat, my }

@immutable
class AppSession {
  const AppSession({
    this.phase = AppPhase.splash,
    this.isLoggedIn = false,
    this.onboardingCompleted = false,
    this.profileCompleted = false,
    this.goal,
    this.mainTab = MainTab.home,
    this.uid,
  });

  final AppPhase phase;
  final bool isLoggedIn;
  final bool onboardingCompleted;
  final bool profileCompleted;
  final UserGoal? goal;
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
    UserGoal? goal,
    bool clearGoal = false,
    MainTab? mainTab,
    String? uid,
    bool clearUid = false,
  }) {
    return AppSession(
      phase: phase ?? this.phase,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      goal: clearGoal ? null : (goal ?? this.goal),
      mainTab: mainTab ?? this.mainTab,
      uid: clearUid ? null : (uid ?? this.uid),
    );
  }
}

/// Owns splash → onboarding → login → goal → profile → main.
///
/// Feature screens should read auth here, not replace this machine:
/// - [AppSession.uid] / [AppSession.isLoggedIn]
/// - [authStateChangesProvider] / [currentAuthUserProvider]
class SessionNotifier extends Notifier<AppSession> {
  @override
  AppSession build() => const AppSession();

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  /// After splash: a persisted Firebase user skips login (and onboarding),
  /// but still hits goal/profile gates until those flags are set.
  void completeSplash() {
    final user = _auth.currentUser;
    if (user != null) {
      state = state.copyWith(
        isLoggedIn: true,
        onboardingCompleted: true,
        uid: user.uid,
        phase: _phaseForSignedInUser(),
      );
      return;
    }
    state = state.copyWith(phase: AppPhase.onboarding);
  }

  AppPhase _phaseForSignedInUser() {
    if (state.profileCompleted) return AppPhase.main;
    if (state.goal != null) return AppPhase.profile;
    return AppPhase.goal;
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
  /// Likes stay locked until [UserDoc] listen sees `verifiedAt`.
  void completeLogin() {
    state = state.copyWith(
      isLoggedIn: true,
      phase: AppPhase.goal,
      uid: _auth.currentUser?.uid,
    );
  }

  Future<void> signInWithGoogle() async {
    await _auth.signInWithGoogle();
    completeLogin();
  }

  Future<void> signInWithApple() async {
    await _auth.signInWithApple();
    completeLogin();
  }

  void setGoal(UserGoal goal) {
    state = state.copyWith(goal: goal);
  }

  void confirmGoal() {
    if (state.goal == null) return;
    state = state.copyWith(phase: AppPhase.profile);
  }

  void backFromProfile() {
    state = state.copyWith(phase: AppPhase.goal);
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
    await _auth.signOut();
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
