import 'dart:typed_data';

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
    this.bytes,
    this.assetPath,
    this.imageUrl,
    this.borderRadius,
    this.circle = false,
    this.iconSize,
  });

  final int seed;
  final Uint8List? bytes;
  final String? assetPath;
  final String? imageUrl;
  final BorderRadius? borderRadius;
  final bool circle;
  final double? iconSize;

  Color get _bg => _photoPalette[seed.abs() % _photoPalette.length];

  @override
  Widget build(BuildContext context) {
    final hasBytes = bytes != null && bytes!.isNotEmpty;
    final hasAsset = assetPath != null && assetPath!.isNotEmpty;
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    final Widget child;
    if (hasBytes) {
      child = Image.memory(
        bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (hasAsset) {
      child = Image.asset(
        assetPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _Placeholder(bg: _bg, iconSize: iconSize),
      );
    } else if (hasUrl) {
      child = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _Placeholder(bg: _bg, iconSize: iconSize),
      );
    } else {
      child = _Placeholder(bg: _bg, iconSize: iconSize);
    }

    if (circle) {
      return ClipOval(child: child);
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: child,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.bg, this.iconSize});

  final Color bg;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg,
      child: Center(
        child: Icon(
          Icons.pets_rounded,
          color: AppColors.primary.withValues(alpha: 0.85),
          size: iconSize,
        ),
      ),
    );
  }
}
