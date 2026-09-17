import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/common.dart';

class P00OwnerInfoStep extends ConsumerWidget {
  const P00OwnerInfoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final notifier = ref.read(profileDraftProvider.notifier);

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
          Text(AppCopy.p00Title, style: AppTypography.display),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppCopy.p00Subtitle,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _Label(AppCopy.ownerAgeLabel),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final band in OwnerAgeBand.values)
                SelectableChip(
                  label: _ageLabel(band),
                  selected: draft.ownerAgeBand == band,
                  onTap: () => notifier.setOwnerAgeBand(band),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Label(AppCopy.ownerGenderLabel),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              SelectableChip(
                label: AppCopy.ownerGenderMale,
                selected: draft.ownerGender == OwnerGender.male,
                onTap: () => notifier.setOwnerGender(OwnerGender.male),
              ),
              SelectableChip(
                label: AppCopy.ownerGenderFemale,
                selected: draft.ownerGender == OwnerGender.female,
                onTap: () => notifier.setOwnerGender(OwnerGender.female),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Label(AppCopy.dogExperienceLabel),
          Text(
            AppCopy.dogExperienceHint,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final exp in DogExperience.values)
                SelectableChip(
                  label: _experienceLabel(exp),
                  selected: draft.dogExperience == exp,
                  onTap: () => notifier.setDogExperience(exp),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _ageLabel(OwnerAgeBand band) => switch (band) {
        OwnerAgeBand.twenties => AppCopy.ownerAgeTwenties,
        OwnerAgeBand.thirties => AppCopy.ownerAgeThirties,
        OwnerAgeBand.forties => AppCopy.ownerAgeForties,
        OwnerAgeBand.fiftiesPlus => AppCopy.ownerAgeFiftiesPlus,
      };

  static String _experienceLabel(DogExperience exp) => switch (exp) {
        DogExperience.firstTime => AppCopy.dogExperienceFirst,
        DogExperience.underOneYear => AppCopy.dogExperienceUnderOne,
        DogExperience.oneToThree => AppCopy.dogExperienceOneToThree,
        DogExperience.threeToFive => AppCopy.dogExperienceThreeToFive,
        DogExperience.overFive => AppCopy.dogExperienceOverFive,
      };
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: AppTypography.button),
    );
  }
}
