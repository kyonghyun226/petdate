import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';

class O01GoalScreen extends ConsumerWidget {
  const O01GoalScreen({
    super.key,
    this.popOnConfirm = false,
  });

  /// When opened from Y01, apply goal and pop instead of entering the wizard.
  final bool popOnConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(sessionProvider.select((s) => s.goal));

    return Scaffold(
      appBar: popOnConfirm
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(AppCopy.goalQuestion, style: AppTypography.display),
              const SizedBox(height: AppSpacing.xxl),
              _GoalCard(
                icon: Icons.pets_rounded,
                title: AppCopy.goalFriendTitle,
                description: AppCopy.goalFriendDesc,
                selected: goal == UserGoal.friend,
                onTap: () => ref
                    .read(sessionProvider.notifier)
                    .setGoal(UserGoal.friend),
              ),
              const SizedBox(height: AppSpacing.md),
              _GoalCard(
                icon: Icons.directions_walk_rounded,
                title: AppCopy.goalWalkTitle,
                description: AppCopy.goalWalkDesc,
                selected: goal == UserGoal.walk,
                onTap: () =>
                    ref.read(sessionProvider.notifier).setGoal(UserGoal.walk),
              ),
              const Spacer(),
              PrimaryButton(
                label: popOnConfirm ? AppCopy.goalApply : AppCopy.next,
                onPressed: goal == null
                    ? null
                    : () {
                        if (popOnConfirm) {
                          ref.read(sessionProvider.notifier).applyGoal();
                          Navigator.of(context).pop();
                        } else {
                          ref.read(sessionProvider.notifier).confirmGoal();
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.title.copyWith(fontSize: 18)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTypography.caption.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
