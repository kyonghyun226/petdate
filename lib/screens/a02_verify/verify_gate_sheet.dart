import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';

/// Unverified like/D01 CTA sheet. Primary → A02, secondary dismisses.
Future<bool> showVerifyGateSheet(BuildContext context) async {
  final go = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheetTop),
      ),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppCopy.verifyGateTitle, style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            Text(AppCopy.verifyGateBody, style: AppTypography.body),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              key: const ValueKey('verify-sheet-go'),
              label: AppCopy.verifyGateCta,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              key: const ValueKey('verify-sheet-later'),
              label: AppCopy.later,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return go == true;
}
