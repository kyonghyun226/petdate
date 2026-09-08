import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    this.verifiedAt,
  });

  final AppPhase phase;
  final bool isLoggedIn;
  final bool onboardingCompleted;
  final bool profileCompleted;
  final UserGoal? goal;
  final MainTab mainTab;

  /// Mock `users/{uid}` document id. Real Auth uid lands here after Google/Apple.
  final String? uid;

  /// Local stand-in for a `users/{uid}.verifiedAt` **read/listen**.
  /// Never written to Firestore from the client.
  final DateTime? verifiedAt;

  bool get isVerified => verifiedAt != null;

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
    DateTime? verifiedAt,
    bool clearVerifiedAt = false,
  }) {
    return AppSession(
      phase: phase ?? this.phase,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      goal: clearGoal ? null : (goal ?? this.goal),
      mainTab: mainTab ?? this.mainTab,
      uid: clearUid ? null : (uid ?? this.uid),
      verifiedAt: clearVerifiedAt ? null : (verifiedAt ?? this.verifiedAt),
    );
  }
}

class SessionNotifier extends Notifier<AppSession> {
  @override
  AppSession build() => const AppSession();

  void completeSplash() {
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

  /// Mock social login. Real Google/Apple auth is out of scope.
  ///
  /// Does **not** unlock likes. A02 mock / user-doc listen must run first.
  void mockLogin() {
    state = state.copyWith(
      isLoggedIn: true,
      phase: AppPhase.goal,
      uid: 'mock_uid',
      clearVerifiedAt: true,
    );
  }

  /// Mock of a `users/{uid}` snapshot that already has `verifiedAt`.
  /// Not a Firestore write.
  void unlockFromUserDocMock({DateTime? verifiedAt}) {
    state = state.copyWith(
      verifiedAt: (verifiedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Test helper: pretend the user-doc listen already saw `verifiedAt`.
  void mockVerifyIdentity() {
    unlockFromUserDocMock(verifiedAt: DateTime.utc(2026, 9, 8));
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
}

final sessionProvider = NotifierProvider<SessionNotifier, AppSession>(
  SessionNotifier.new,
);

/// Bumps mock stores when the user logs out.
final sessionLoggedInTickProvider = Provider<int>((ref) {
  final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));
  return loggedIn ? 1 : 0;
});
