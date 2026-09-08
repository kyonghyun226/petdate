import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';

Future<void> showR01ReportSheet(
  BuildContext context,
  DiscoveryProfile profile,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
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
          Text(AppCopy.reportTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${profile.name} · ${AppCopy.reportHint}',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.xl),
          SecondaryButton(
            label: AppCopy.blockLabel,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSizes.buttonHeight,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: const Text(AppCopy.reportLabel),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppCopy.close),
          ),
        ],
      ),
    ),
  );
}
