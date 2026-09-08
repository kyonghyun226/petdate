import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';

const pushPrepromptKey = ValueKey<String>('push-preprompt');
const pushPrepromptAllowKey = ValueKey<String>('push-preprompt-allow');
const pushPrepromptDenyKey = ValueKey<String>('push-preprompt-deny');

/// Optional in-app ask before the OS dialog. Deny is non-blocking.
Future<bool> showPushPreprompt(BuildContext context) async {
  final allowed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        key: pushPrepromptKey,
        backgroundColor: AppColors.surface,
        title: Text(AppCopy.pushPrepromptTitle, style: AppTypography.title),
        content: Text(AppCopy.pushPrepromptBody, style: AppTypography.body),
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        actions: [
          SecondaryButton(
            key: pushPrepromptDenyKey,
            label: AppCopy.pushPrepromptDeny,
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          const SizedBox(width: AppSpacing.sm),
          PrimaryButton(
            key: pushPrepromptAllowKey,
            label: AppCopy.pushPrepromptAllow,
            expand: false,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      );
    },
  );
  return allowed == true;
}
