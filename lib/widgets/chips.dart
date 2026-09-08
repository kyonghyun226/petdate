import 'package:flutter/material.dart';
import 'package:petdate/models/pet_tag.dart';
import 'package:petdate/models/preferred_time.dart';
import 'package:petdate/theme/tokens.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.tiny = false,
  });

  final String label;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tiny ? AppSpacing.sm : AppSpacing.md,
        vertical: tiny ? 2 : AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: tiny ? 11 : 13,
          color: AppColors.text,
        ),
      ),
    );
  }
}

class TagKeyWrap extends StatelessWidget {
  const TagKeyWrap({
    super.key,
    required this.keys,
    this.limit,
    this.tiny = false,
  });

  final Iterable<String> keys;
  final int? limit;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    final shown = limit == null ? keys : keys.take(limit!);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final key in shown) TagChip(label: PetTags.labelOf(key), tiny: tiny),
      ],
    );
  }
}

class TimeSlotChips extends StatelessWidget {
  const TimeSlotChips({
    super.key,
    required this.slots,
    this.tiny = false,
  });

  final Iterable<PreferredTimeSlot> slots;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final slot in slots)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tiny ? AppSpacing.sm : AppSpacing.md,
              vertical: tiny ? 2 : AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              PreferredTimeCopy.label(slot),
              style: AppTypography.caption.copyWith(
                fontSize: tiny ? 11 : 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
