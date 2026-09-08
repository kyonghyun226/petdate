import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _timer = Timer(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      final remote = await SessionBootstrap.load();
      if (!mounted) return;
      if (remote != null) {
        if (remote.pet != null) {
          ref.read(profileDraftProvider.notifier).hydrate(remote.pet!);
        }
        if (remote.verifiedAt != null) {
          ref.read(userDocProvider.notifier).applyRemoteSnapshot(
                verifiedAt: remote.verifiedAt,
              );
        }
      }
      if (!mounted) return;
      ref.read(sessionProvider.notifier).completeSplash(
            remoteGoal: remote?.goal,
            remoteProfileCompleted: remote?.pet != null,
          );
    });
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
