import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/data/backend_mode.dart';
import 'package:petdate/data/demo_mode.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/location/geo.dart';
import 'package:petdate/location/location_providers.dart';
import 'package:petdate/state/feed_provider.dart';
import 'package:petdate/state/session_provider.dart';

void main() {
  test('demo catalog stays visible after GPS origin is set', () {
    DemoMode.disableForTests();
    final container = ProviderContainer(
      overrides: [
        useMockDataProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    final session = container.read(sessionProvider.notifier);
    session.completeSplash();
    session.completeOnboarding();
    session.completeLogin();
    session.completeProfile();

    final before = container.read(feedProvider);
    expect(before.remaining, isNotEmpty);
    expect(before.remaining.length, MockCatalog.profiles.length);
    expect(before.remaining.first.distanceKm, greaterThan(0));

    // Simulate location grant (admin account).
    container.read(myLocationProvider.notifier).set(
          const ApproxLatLng(37.57, 126.98),
        );

    final after = container.read(feedProvider);
    expect(after.remaining, isNotEmpty);
    expect(after.remaining.length, MockCatalog.profiles.length);
    // Baked demo distances must survive GPS remap.
    expect(after.remaining.first.distanceKm, before.remaining.first.distanceKm);
  });
}
