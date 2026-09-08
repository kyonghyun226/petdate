import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/theme/tokens.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final MainTab current;
  final ValueChanged<MainTab> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sparkBadge = ref.watch(
      sparkProvider.select((s) => s.unseenReceivedCount),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.tabBarHeight,
          child: Row(
            children: [
              _Item(
                label: AppCopy.navHome,
                selected: current == MainTab.home,
                outlined: Icons.home_outlined,
                filled: Icons.home_rounded,
                onTap: () => onSelect(MainTab.home),
              ),
              _Item(
                label: AppCopy.navSpark,
                selected: current == MainTab.spark,
                outlined: Icons.auto_awesome_outlined,
                filled: Icons.auto_awesome,
                badgeCount: sparkBadge,
                onTap: () => onSelect(MainTab.spark),
              ),
              _Item(
                label: AppCopy.navChat,
                selected: current == MainTab.chat,
                outlined: Icons.chat_bubble_outline_rounded,
                filled: Icons.chat_bubble_rounded,
                onTap: () => onSelect(MainTab.chat),
              ),
              _Item(
                label: AppCopy.navMy,
                selected: current == MainTab.my,
                outlined: Icons.person_outline_rounded,
                filled: Icons.person_rounded,
                onTap: () => onSelect(MainTab.my),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.selected,
    required this.outlined,
    required this.filled,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final bool selected;
  final IconData outlined;
  final IconData filled;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.tabInactive;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(selected ? filled : outlined, color: color, size: 24),
                  if (badgeCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: _Badge(count: badgeCount),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      key: const ValueKey('spark-badge'),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
