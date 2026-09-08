import 'package:flutter/material.dart';
import 'package:petdate/theme/tokens.dart';

const _photoPalette = <Color>[
  Color(0xFFFFE5DE),
  Color(0xFFE8F7F3),
  Color(0xFFFFF3D6),
  Color(0xFFE8EEFF),
  Color(0xFFF3E8FF),
];

class PetPhoto extends StatelessWidget {
  const PetPhoto({
    super.key,
    required this.seed,
    this.borderRadius,
    this.circle = false,
    this.iconSize,
  });

  final int seed;
  final BorderRadius? borderRadius;
  final bool circle;
  final double? iconSize;

  Color get _bg => _photoPalette[seed.abs() % _photoPalette.length];

  @override
  Widget build(BuildContext context) {
    final child = ColoredBox(
      color: _bg,
      child: Center(
        child: Icon(
          Icons.pets_rounded,
          color: AppColors.primary.withValues(alpha: 0.85),
          size: iconSize,
        ),
      ),
    );

    if (circle) {
      return ClipOval(child: child);
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: child,
    );
  }
}
