import 'package:flutter/material.dart';
import 'package:petdate/theme/brand_assets.dart';

/// 「코인사」 icon from [BrandAssets.nose] / filled variant.
class DogNoseIcon extends StatelessWidget {
  const DogNoseIcon({
    super.key,
    this.size = 22,
    this.filled = false,
  });

  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      filled ? BrandAssets.noseFilled : BrandAssets.nose,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}
