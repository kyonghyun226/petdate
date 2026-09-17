import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/location/location_providers.dart';
import 'package:petdate/state/session_provider.dart';

/// Asks for location on first main entry. Never requests at splash/login.
class LocationHost extends ConsumerStatefulWidget {
  const LocationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LocationHost> createState() => _LocationHostState();
}

class _LocationHostState extends ConsumerState<LocationHost>
    with WidgetsBindingObserver {
  bool _askedThisAttach = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(locationCoordinatorProvider).attach();
      if (!mounted) return;
      await _tryAsk();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationCoordinatorProvider).syncIfAllowed();
    }
  }

  Future<void> _tryAsk() async {
    if (_askedThisAttach) return;
    if (ref.read(sessionProvider).phase != AppPhase.main) return;
    if (!mounted) return;
    _askedThisAttach = true;
    await ref.read(locationCoordinatorProvider).maybeAskOnMain(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppPhase>(sessionProvider.select((s) => s.phase), (prev, next) {
      if (next == AppPhase.main && prev != AppPhase.main) {
        _askedThisAttach = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _tryAsk();
        });
      }
    });
    ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn), (prev, next) {
      if (prev == true && next == false) {
        _askedThisAttach = false;
        ref.read(locationCoordinatorProvider).onSignedOut();
        ref.read(myLocationProvider.notifier).set(null);
      }
    });
    return widget.child;
  }
}
