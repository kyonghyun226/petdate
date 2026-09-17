import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/firebase/session_bootstrap.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/common.dart';

class S01SplashScreen extends ConsumerStatefulWidget {
  const S01SplashScreen({super.key});

  @override
  ConsumerState<S01SplashScreen> createState() => _S01SplashScreenState();
}

class _S01SplashScreenState extends ConsumerState<S01SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      unawaited(_finishSplash());
    });
  }

  /// Give Firebase Auth a short window to restore a Keychain session after
  /// cold start. Prefer [currentUser] after the wait over trusting an early
  /// null from [authStateChanges].
  Future<AuthUser?> _waitForRestoredAuth() async {
    final auth = ref.read(authRepositoryProvider);
    if (auth.currentUser != null) return auth.currentUser;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return auth.currentUser;
  }

  Future<void> _finishSplash() async {
    if (!mounted) return;
    await _waitForRestoredAuth();
    if (!mounted) return;

    final remote = await SessionBootstrap.load();
    if (!mounted) return;

    final hasPet = remote != null && !remote.loadFailed && remote.pet != null;
    // Mark session logged-in before hydrate so login-tick listeners that
    // reset stores have already fired (profile draft must not rebuild after).
    ref.read(sessionProvider.notifier).completeSplash(
          remoteProfileCompleted: hasPet,
        );
    if (!mounted) return;
    if (remote != null && !remote.loadFailed) {
      if (remote.pet != null) {
        ref.read(profileDraftProvider.notifier).hydrate(remote.pet!);
      }
      if (remote.verifiedAt != null) {
        ref.read(userDocProvider.notifier).applyRemoteSnapshot(
              verifiedAt: remote.verifiedAt,
            );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: BrandMark(iconSize: 96, wordmarkHeight: 42),
      ),
    );
  }
}
