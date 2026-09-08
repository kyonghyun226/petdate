import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/common.dart';

class Y01MyScreen extends ConsumerWidget {
  const Y01MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(sessionProvider.select((s) => s.goal));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppCopy.navMy),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EmptyState(
              message: AppCopy.myPlaceholder,
              icon: Icons.person_outline_rounded,
            ),
            if (goal != null)
              Text(
                '지금 목적 · ${GoalCopy.goalChipLabel(goal)}',
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
          ],
        ),
      ),
    );
  }
}
