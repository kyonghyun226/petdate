import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/theme/brand_assets.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/brand_wordmark.dart';
import 'package:petdate/widgets/buttons.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.current,
    this.total = 4,
  });

  /// 0-based current step.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i <= current ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
            ),
          ),
          if (i != total - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primarySoft : AppColors.surfaceMuted;
    final border = selected ? AppColors.primary : Colors.transparent;
    final fg = enabled ? AppColors.text : AppColors.textMuted;

    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border, width: 1.5)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 2,
          ),
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: fg,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.showWordmark = true,
    this.iconSize = 64,
    this.wordmarkHeight = 36,
  });

  final bool showWordmark;
  final double iconSize;
  final double wordmarkHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          BrandAssets.appIcon,
          width: iconSize,
          height: iconSize,
          filterQuality: FilterQuality.high,
          semanticLabel: AppCopy.appName,
        ),
        if (showWordmark) ...[
          const SizedBox(height: AppSpacing.md),
          BrandWordmark(height: wordmarkHeight),
        ],
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.auto_awesome_outlined,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Icon(icon, color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
