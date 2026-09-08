import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/feed_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';

Future<void> showR01ReportSheet(
  BuildContext context,
  DiscoveryProfile profile,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _R01ReportSheet(profile: profile),
  );
}

class _R01ReportSheet extends ConsumerWidget {
  const _R01ReportSheet({required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Text(AppCopy.reportTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${profile.name} · ${AppCopy.reportHint}',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.xl),
          SecondaryButton(
            label: AppCopy.blockLabel,
            onPressed: () async {
              final uid = ref.read(sessionProvider).uid;
              ref.read(sparkProvider.notifier).block(profile.id);
              ref.read(feedProvider.notifier).dismiss(profile.id);
              if (uid != null) {
                await ref
                    .read(socialRepositoryProvider)
                    .blockUser(blockerId: uid, blockedId: profile.id);
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSizes.buttonHeight,
            child: OutlinedButton(
              onPressed: () async {
                final uid = ref.read(sessionProvider).uid;
                if (uid != null) {
                  await ref
                      .read(socialRepositoryProvider)
                      .reportTarget(
                        reporterId: uid,
                        targetType: 'pet',
                        targetId: profile.id,
                        reason: 'other',
                      );
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppCopy.reportSent)),
                );
              },
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
    );
  }
}
