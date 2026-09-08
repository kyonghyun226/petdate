import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/theme/tokens.dart';

/// Mint “인증됨” chip for Y01 / D01 / A02 success.
class TrustBadge extends StatelessWidget {
  const TrustBadge({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 14.0 : 18.0;
    return Container(
      key: const ValueKey('trust-badge'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.safetyBg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: iconSize,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            AppCopy.verifyStatusVerified,
            style: AppTypography.caption.copyWith(
              color: AppColors.safetyText,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
