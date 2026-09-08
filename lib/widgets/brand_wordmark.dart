import 'package:flutter/material.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/theme/brand_assets.dart';
import 'package:petdate/theme/tokens.dart';

/// Wordmark v3 slot. PNG when [BrandAssets.hasWordmarkImage], otherwise
/// dual-tone text: coral 「반짝」 + charcoal 「산책」 + coral ✦.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    if (BrandAssets.hasWordmarkImage) {
      return Image.asset(
        BrandAssets.wordmark,
        height: height,
        filterQuality: FilterQuality.high,
        semanticLabel: AppCopy.appName,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '✦',
          style: AppTypography.title.copyWith(
            fontSize: height - 6,
            color: AppColors.primary,
            height: 1,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text.rich(
          TextSpan(
            style: AppTypography.title.copyWith(fontSize: 22, height: 1),
            children: const [
              TextSpan(
                text: BrandAssets.wordmarkHalfSpark,
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(
                text: BrandAssets.wordmarkHalfWalk,
                style: TextStyle(color: AppColors.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
