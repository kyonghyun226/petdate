import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/pet_tag.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/common.dart';

class P03TagsStep extends ConsumerWidget {
  const P03TagsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final notifier = ref.read(profileDraftProvider.notifier);
    final atMaxTags = draft.tags.length >= ProfileDraft.maxTags;
    final atMaxTimes =
        draft.preferredTimeSlots.length >= ProfileDraft.maxTimeSlots;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppCopy.p03Title, style: AppTypography.display),
          const SizedBox(height: AppSpacing.md),
          Text(AppCopy.tagHint, style: AppTypography.body),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${draft.tags.length} / ${ProfileDraft.maxTags}  ·  ${AppCopy.tagCount}',
            style: AppTypography.caption.copyWith(
              color: draft.p03TagsValid ? AppColors.textMuted : AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in PetTags.all)
                SelectableChip(
                  label: tag.label,
                  selected: draft.tags.contains(tag.key),
                  enabled: draft.tags.contains(tag.key) || !atMaxTags,
                  onTap: () => notifier.toggleTag(tag.key),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(AppCopy.p03TimeTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text(AppCopy.p03TimeHint, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${draft.preferredTimeSlots.length} / ${ProfileDraft.maxTimeSlots}',
            style: AppTypography.caption.copyWith(
              color:
                  draft.p03TimesValid ? AppColors.textMuted : AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final slot in PreferredTimeSlot.values)
                SelectableChip(
                  label: PreferredTimeCopy.label(slot),
                  selected: draft.preferredTimeSlots.contains(slot),
                  enabled:
                      draft.preferredTimeSlots.contains(slot) || !atMaxTimes,
                  onTap: () => notifier.toggleTimeSlot(slot),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
