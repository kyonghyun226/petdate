import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/copy/species_copy.dart';
import 'package:petdate/models/pet_tag.dart';
import 'package:petdate/screens/o01_goal/o01_goal_screen.dart';
import 'package:petdate/screens/y01_settings/y01_settings_screen.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/pet_photo.dart';

class Y01MyScreen extends ConsumerWidget {
  const Y01MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(sessionProvider.select((s) => s.goal));
    final draft = ref.watch(profileDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppCopy.navMy),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          _PetSummaryCard(draft: draft, goal: goal),
          const SizedBox(height: AppSpacing.xl),
          _MenuTile(
            icon: Icons.flag_outlined,
            label: AppCopy.myChangeGoal,
            trailing: goal == null ? null : GoalCopy.goalChipLabel(goal),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const O01GoalScreen(popOnConfirm: true),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            label: AppCopy.mySettings,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Y01SettingsScreen(),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: AppCopy.myLogout,
            danger: true,
            onTap: () => ref.read(sessionProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _PetSummaryCard extends StatelessWidget {
  const _PetSummaryCard({required this.draft, required this.goal});

  final ProfileDraft draft;
  final UserGoal? goal;

  @override
  Widget build(BuildContext context) {
    final age = draft.displayAgeYears;
    final tags = draft.tags.take(3);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: PetPhoto(
              seed: draft.primaryPhotoSeed,
              circle: true,
              iconSize: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.displayName, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    if (draft.breed.trim().isNotEmpty) draft.breed.trim(),
                    if (age != null) '$age살',
                    if (draft.species != null) SpeciesCopy.noun(draft.species),
                  ].join(' · '),
                  style: AppTypography.caption,
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    tags.map(PetTags.labelOf).join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
                if (goal != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    GoalCopy.goalChipLabel(goal!),
                    style: AppTypography.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.text;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!, style: AppTypography.caption),
          const Icon(Icons.chevron_right_rounded, color: AppColors.tabInactive),
        ],
      ),
      onTap: onTap,
    );
  }
}
