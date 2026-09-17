import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';

const locationPrepromptKey = ValueKey<String>('location-preprompt');
const locationPrepromptAllowKey = ValueKey<String>('location-preprompt-allow');
const locationPrepromptDenyKey = ValueKey<String>('location-preprompt-deny');

/// Optional in-app ask before the OS location dialog. Deny is non-blocking.
Future<bool> showLocationPreprompt(BuildContext context) async {
  final allowed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        key: locationPrepromptKey,
        backgroundColor: AppColors.surface,
        title: Text(AppCopy.locationPrepromptTitle, style: AppTypography.title),
        content: Text(AppCopy.locationPrepromptBody, style: AppTypography.body),
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        actions: [
          SecondaryButton(
            key: locationPrepromptDenyKey,
            label: AppCopy.locationPrepromptDeny,
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          const SizedBox(width: AppSpacing.sm),
          PrimaryButton(
            key: locationPrepromptAllowKey,
            label: AppCopy.locationPrepromptAllow,
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      );
    },
  );
  return allowed == true;
}
