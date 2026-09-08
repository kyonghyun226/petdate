import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/common.dart';

class P03TagsStep extends ConsumerWidget {
  const P03TagsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final notifier = ref.read(profileDraftProvider.notifier);
    final atMax = draft.tags.length >= ProfileDraft.maxTags;

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
            color: draft.p03Valid ? AppColors.textMuted : AppColors.danger,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tag in AppCopy.petTags)
              SelectableChip(
                label: tag,
                selected: draft.tags.contains(tag),
                enabled: draft.tags.contains(tag) || !atMax,
                onTap: () => notifier.toggleTag(tag),
              ),
          ],
        ),
        ],
      ),
    );
  }
}
