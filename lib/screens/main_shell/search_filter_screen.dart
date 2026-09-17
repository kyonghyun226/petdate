import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/pet_tag.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/search_filter_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/common.dart';

class SearchFilterScreen extends ConsumerStatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  late SearchFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(searchFilterProvider);
  }

  void _set(SearchFilter next) => setState(() => _draft = next);

  Set<T> _toggle<T>(Set<T> current, T value) {
    final next = {...current};
    if (!next.add(value)) next.remove(value);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(AppCopy.filterTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppCopy.filterSubtitle,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionTitle(AppCopy.filterRadiusLabel),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final km in SearchFilter.radiusOptionsKm)
                        SelectableChip(
                          label: '${km.round()}km',
                          selected: _draft.radiusKm == km,
                          onTap: () => _set(_draft.copyWith(radiusKm: km)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionTitle(AppCopy.filterPetSection),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(AppCopy.genderLabel),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final g in PetGender.values)
                        SelectableChip(
                          label: g == PetGender.male
                              ? AppCopy.genderMale
                              : AppCopy.genderFemale,
                          selected: _draft.petGenders.contains(g),
                          onTap: () => _set(
                            _draft.copyWith(
                              petGenders: _toggle(_draft.petGenders, g),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel(AppCopy.sizeLabel),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final s in PetSize.values)
                        SelectableChip(
                          label: switch (s) {
                            PetSize.small => AppCopy.sizeSmall,
                            PetSize.medium => AppCopy.sizeMedium,
                            PetSize.large => AppCopy.sizeLarge,
                          },
                          selected: _draft.petSizes.contains(s),
                          onTap: () => _set(
                            _draft.copyWith(
                              petSizes: _toggle(_draft.petSizes, s),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel(AppCopy.filterAgeLabel),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final band in PetAgeBand.values)
                        SelectableChip(
                          label: switch (band) {
                            PetAgeBand.underOne => AppCopy.filterAgeUnderOne,
                            PetAgeBand.oneToThree =>
                              AppCopy.filterAgeOneToThree,
                            PetAgeBand.threeToSeven =>
                              AppCopy.filterAgeThreeToSeven,
                            PetAgeBand.overSeven => AppCopy.filterAgeOverSeven,
                          },
                          selected: _draft.petAgeBands.contains(band),
                          onTap: () => _set(
                            _draft.copyWith(
                              petAgeBands: _toggle(_draft.petAgeBands, band),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel(AppCopy.filterTagsLabel),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final tag in PetTags.all)
                        SelectableChip(
                          label: tag.label,
                          selected: _draft.tagKeys.contains(tag.key),
                          onTap: () => _set(
                            _draft.copyWith(
                              tagKeys: _toggle(_draft.tagKeys, tag.key),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel(AppCopy.filterTimeLabel),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final slot in PreferredTimeSlot.values)
                        SelectableChip(
                          label: PreferredTimeCopy.label(slot),
                          selected: _draft.timeSlots.contains(slot),
                          onTap: () => _set(
                            _draft.copyWith(
                              timeSlots: _toggle(_draft.timeSlots, slot),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionTitle(AppCopy.filterOwnerSection),
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(AppCopy.ownerAgeLabel),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final band in OwnerAgeBand.values)
                        SelectableChip(
                          label: switch (band) {
                            OwnerAgeBand.twenties => AppCopy.ownerAgeTwenties,
                            OwnerAgeBand.thirties => AppCopy.ownerAgeThirties,
                            OwnerAgeBand.forties => AppCopy.ownerAgeForties,
                            OwnerAgeBand.fiftiesPlus =>
                              AppCopy.ownerAgeFiftiesPlus,
                          },
                          selected: _draft.ownerAgeBands.contains(band),
                          onTap: () => _set(
                            _draft.copyWith(
                              ownerAgeBands:
                                  _toggle(_draft.ownerAgeBands, band),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel(AppCopy.ownerGenderLabel),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final g in OwnerGender.values)
                        SelectableChip(
                          label: g == OwnerGender.male
                              ? AppCopy.ownerGenderMale
                              : AppCopy.ownerGenderFemale,
                          selected: _draft.ownerGenders.contains(g),
                          onTap: () => _set(
                            _draft.copyWith(
                              ownerGenders: _toggle(_draft.ownerGenders, g),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel(AppCopy.dogExperienceLabel),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final exp in DogExperience.values)
                        SelectableChip(
                          label: switch (exp) {
                            DogExperience.firstTime =>
                              AppCopy.dogExperienceFirst,
                            DogExperience.underOneYear =>
                              AppCopy.dogExperienceUnderOne,
                            DogExperience.oneToThree =>
                              AppCopy.dogExperienceOneToThree,
                            DogExperience.threeToFive =>
                              AppCopy.dogExperienceThreeToFive,
                            DogExperience.overFive =>
                              AppCopy.dogExperienceOverFive,
                          },
                          selected: _draft.dogExperiences.contains(exp),
                          onTap: () => _set(
                            _draft.copyWith(
                              dogExperiences:
                                  _toggle(_draft.dogExperiences, exp),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: AppColors.surface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.lg + bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: AppCopy.filterReset,
                      onPressed: () => _set(SearchFilter.empty),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: AppCopy.filterApply,
                      onPressed: () {
                        ref
                            .read(searchFilterProvider.notifier)
                            .replace(_draft);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.title.copyWith(fontSize: 17),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
