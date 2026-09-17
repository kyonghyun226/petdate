import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petdate/app.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/data/demo_mode.dart';
import 'package:petdate/location/location_providers.dart';
import 'package:petdate/location/location_prompt_store.dart';
import 'package:petdate/location/location_service.dart';
import 'package:petdate/media/gallery_photo_picker.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:riverpod/misc.dart' show Override;

import 'fake_auth_repository.dart';

List<Override> testOverrides({AuthRepository? auth}) {
  DemoMode.disableForTests();
  return [
      authRepositoryProvider.overrideWith(
        (ref) => auth ?? FakeAuthRepository(),
      ),
      galleryPhotoPickerProvider.overrideWith(
        (ref) => FakeGalleryPhotoPicker(),
      ),
      locationPromptStoreProvider.overrideWith(
        (ref) => InMemoryLocationPromptStore(hasAsked: true),
      ),
      locationServiceProvider.overrideWith(
        (ref) => FakeLocationService(),
      ),
    ];
}

ProviderContainer testContainer({AuthRepository? auth}) {
  return ProviderContainer(
    overrides: testOverrides(auth: auth),
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
    overrides: testOverrides(auth: auth),
    child: const PetdateApp(),
  );
}

void seedCompletedSession(ProviderContainer container) {
  final session = container.read(sessionProvider.notifier);
  session.completeSplash();
  session.completeOnboarding();
  session.completeLogin();
  session.completeProfile();
}

/// Brand splash (1.4s) + Auth restore grace (~350ms).
Future<void> pumpPastSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2000));
  await tester.pumpAndSettle();
}
