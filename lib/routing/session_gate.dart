import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/screens/a01_login/a01_login_screen.dart';
import 'package:petdate/screens/main_shell/main_shell.dart';
import 'package:petdate/screens/o01_goal/o01_goal_screen.dart';
import 'package:petdate/screens/p_profile_wizard/profile_wizard_screen.dart';
import 'package:petdate/screens/s01_splash/s01_splash_screen.dart';
import 'package:petdate/screens/s02_onboarding/s02_onboarding_screen.dart';
import 'package:petdate/state/session_provider.dart';

/// Maps [AppSession.phase] to the matching screen ID.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(sessionProvider.select((s) => s.phase));
    return switch (phase) {
      AppPhase.splash => const S01SplashScreen(),
      AppPhase.onboarding => const S02OnboardingScreen(),
      AppPhase.login => const A01LoginScreen(),
      AppPhase.goal => const O01GoalScreen(),
      AppPhase.profile => const ProfileWizardScreen(),
      AppPhase.main => const MainShell(),
    };
  }
}
