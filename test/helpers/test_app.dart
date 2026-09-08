import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/app.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';

import 'fake_auth_repository.dart';

ProviderContainer testContainer({AuthRepository? auth}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith(
        (ref) => auth ?? FakeAuthRepository(),
      ),
    ],
  );
}

Widget testApp({AuthRepository? auth, ProviderContainer? container}) {
  if (container != null) {
    return UncontrolledProviderScope(
      container: container,
      child: const PetdateApp(),
    );
  }
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWith(
        (ref) => auth ?? FakeAuthRepository(),
      ),
    ],
    child: const PetdateApp(),
  );
}

void seedCompletedSession(
  ProviderContainer container, {
  required UserGoal goal,
}) {
  final session = container.read(sessionProvider.notifier);
  session.completeSplash();
  session.completeOnboarding();
  session.completeLogin();
  session.setGoal(goal);
  session.confirmGoal();
  session.completeProfile();
}
