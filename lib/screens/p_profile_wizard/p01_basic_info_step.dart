import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/common.dart';

class P01BasicInfoStep extends ConsumerStatefulWidget {
  const P01BasicInfoStep({super.key});

  @override
  ConsumerState<P01BasicInfoStep> createState() => _P01BasicInfoStepState();
}

class _P01BasicInfoStepState extends ConsumerState<P01BasicInfoStep> {
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _age;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(profileDraftProvider);
    _name = TextEditingController(text: draft.petName);
    _breed = TextEditingController(text: draft.breed);
    _age = TextEditingController(
      text: draft.ageYears == null ? '' : '${draft.ageYears}',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(profileDraftProvider);
    final notifier = ref.read(profileDraftProvider.notifier);
    final now = DateTime.now();

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
        Text(AppCopy.p01Title, style: AppTypography.display),
        const SizedBox(height: AppSpacing.xl),
        _Label(AppCopy.petNameLabel),
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: AppCopy.petNameHint),
          onChanged: notifier.setPetName,
        ),
        const SizedBox(height: AppSpacing.lg),
        _Label(AppCopy.breedLabel),
        TextField(
          controller: _breed,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: AppCopy.breedHint),
          onChanged: notifier.setBreed,
        ),
        const SizedBox(height: AppSpacing.lg),
        _Label(AppCopy.ageOrBirthLabel),
        Row(
          children: [
            SelectableChip(
              label: AppCopy.ageTab,
              selected: draft.ageInputMode == AgeInputMode.age,
              onTap: () => notifier.setAgeInputMode(AgeInputMode.age),
            ),
            const SizedBox(width: AppSpacing.sm),
            SelectableChip(
              label: AppCopy.birthTab,
              selected: draft.ageInputMode == AgeInputMode.birth,
              onTap: () => notifier.setAgeInputMode(AgeInputMode.birth),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (draft.ageInputMode == AgeInputMode.age)
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: AppCopy.ageHint),
            onChanged: (v) {
              notifier.setAgeYears(v.isEmpty ? null : int.tryParse(v));
            },
          )
        else
          Row(
            children: [
              Expanded(
                child: _FilledSelect<int>(
                  hint: '년',
                  value: draft.birthYear,
                  items: [
                    for (var y = now.year; y >= now.year - 30; y--)
                      (y, '$y'),
                  ],
                  onSelected: (y) => notifier.setBirth(
                    year: y,
                    month: draft.birthMonth,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FilledSelect<int>(
                  hint: '월',
                  value: draft.birthMonth,
                  items: [
                    for (var m = 1; m <= 12; m++) (m, '$m월'),
                  ],
                  onSelected: (m) => notifier.setBirth(
                    year: draft.birthYear,
                    month: m,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        _Label(AppCopy.genderLabel),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            SelectableChip(
              label: AppCopy.genderMale,
              selected: draft.gender == PetGender.male,
              onTap: () => notifier.setGender(PetGender.male),
            ),
            SelectableChip(
              label: AppCopy.genderFemale,
              selected: draft.gender == PetGender.female,
              onTap: () => notifier.setGender(PetGender.female),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Label(AppCopy.sizeLabel),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            SelectableChip(
              label: AppCopy.sizeSmall,
              selected: draft.size == PetSize.small,
              onTap: () => notifier.setSize(PetSize.small),
            ),
            SelectableChip(
              label: AppCopy.sizeMedium,
              selected: draft.size == PetSize.medium,
              onTap: () => notifier.setSize(PetSize.medium),
            ),
            SelectableChip(
              label: AppCopy.sizeLarge,
              selected: draft.size == PetSize.large,
              onTap: () => notifier.setSize(PetSize.large),
            ),
          ],
        ),
      ],
      ),
    );
  }
}

class _FilledSelect<T> extends StatelessWidget {
  const _FilledSelect({
    required this.hint,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  final String hint;
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? hint
        : items.firstWhere((e) => e.$1 == value).$2;
    return PopupMenuButton<T>(
      onSelected: onSelected,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem(value: item.$1, child: Text(item.$2)),
      ],
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: value == null ? AppColors.textMuted : AppColors.text,
                ),
              ),
            ),
            const Icon(Icons.expand_more, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
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
