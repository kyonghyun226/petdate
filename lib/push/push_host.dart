import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/push/push_providers.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';

/// Attaches FCM listeners. Never requests permission (that is M01-only).
class PushHost extends ConsumerStatefulWidget {
  const PushHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushHost> createState() => _PushHostState();
}

class _PushHostState extends ConsumerState<PushHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushCoordinatorProvider).attach();
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
      ref.read(pushCoordinatorProvider).syncTokenIfAllowed();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(sessionProvider.select((s) => s.isLoggedIn), (prev, next) {
      if (prev == true && next == false) {
        ref.read(pushCoordinatorProvider).onSignedOut();
      }
    });
    ref.listen<bool>(isVerifiedProvider, (prev, next) {
      if (next) {
        ref.read(pushCoordinatorProvider).syncTokenIfAllowed();
      }
    });
    return widget.child;
  }
}
