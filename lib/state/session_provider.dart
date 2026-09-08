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
  });

  final AppPhase phase;
  final bool isLoggedIn;
  final bool onboardingCompleted;
  final bool profileCompleted;
  final UserGoal? goal;
  final MainTab mainTab;

  bool get showBottomNav => phase == AppPhase.main && isLoggedIn;

  AppSession copyWith({
    AppPhase? phase,
    bool? isLoggedIn,
    bool? onboardingCompleted,
    bool? profileCompleted,
    UserGoal? goal,
    MainTab? mainTab,
  }) {
    return AppSession(
      phase: phase ?? this.phase,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      goal: goal ?? this.goal,
      mainTab: mainTab ?? this.mainTab,
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
  void mockLogin() {
    state = state.copyWith(
      isLoggedIn: true,
      phase: AppPhase.goal,
    );
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
}

final sessionProvider = NotifierProvider<SessionNotifier, AppSession>(
  SessionNotifier.new,
);
