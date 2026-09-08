import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/flow/spark_actions.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/feed_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/chips.dart';
import 'package:petdate/widgets/common.dart';
import 'package:petdate/widgets/pet_photo.dart';

class H01HomeScreen extends ConsumerWidget {
  const H01HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal =
        ref.watch(sessionProvider.select((s) => s.goal)) ?? UserGoal.friend;
    final feed = ref.watch(feedProvider);
    final current = feed.current;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(GoalCopy.homeTitle(goal)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: _SpeciesFilterBar(
              value: feed.speciesFilter,
              onChanged: ref.read(feedProvider.notifier).setSpeciesFilter,
            ),
          ),
          Expanded(
            child: current == null
                ? EmptyState(
                    message: GoalCopy.homeEmpty(goal),
                    icon: goal == UserGoal.friend
                        ? Icons.pets_outlined
                        : Icons.directions_walk_outlined,
                    actionLabel: AppCopy.refresh,
                    onAction: ref.read(feedProvider.notifier).refresh,
                  )
                : _FocusedCard(profile: current),
          ),
        ],
      ),
    );
  }
}

class _SpeciesFilterBar extends StatelessWidget {
  const _SpeciesFilterBar({required this.value, required this.onChanged});

  final SpeciesFilter value;
  final ValueChanged<SpeciesFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SelectableChip(
          label: AppCopy.filterAll,
          selected: value == SpeciesFilter.all,
          onTap: () => onChanged(SpeciesFilter.all),
        ),
        const SizedBox(width: AppSpacing.sm),
        SelectableChip(
          label: AppCopy.speciesDog,
          selected: value == SpeciesFilter.dog,
          onTap: () => onChanged(SpeciesFilter.dog),
        ),
        const SizedBox(width: AppSpacing.sm),
        SelectableChip(
          label: AppCopy.speciesCat,
          selected: value == SpeciesFilter.cat,
          onTap: () => onChanged(SpeciesFilter.cat),
        ),
      ],
    );
  }
}

class _FocusedCard extends StatelessWidget {
  const _FocusedCard({required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth - AppSizes.cardInset;
        final maxHeight = constraints.maxHeight - AppSpacing.lg;
        final fitted = _fitCard(maxWidth: maxWidth, maxHeight: maxHeight);

        return Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: SizedBox(
                  width: fitted.width,
                  height: fitted.height,
                  child: _ProfileCard(
                    profile: profile,
                    photoHeight: fitted.photoHeight,
                    onTap: () => openProfileDetail(context, profile),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.lg,
              child: _PassLikeFabs(profile: profile),
            ),
          ],
        );
      },
    );
  }

  static ({double width, double height, double photoHeight}) _fitCard({
    required double maxWidth,
    required double maxHeight,
  }) {
    var width = maxWidth;
    var photoHeight = width / AppSizes.cardPhotoAspect;
    var height = photoHeight / AppSizes.cardPhotoShare;
    if (height > maxHeight && maxHeight > 0) {
      final scale = maxHeight / height;
      width *= scale;
      photoHeight *= scale;
      height = maxHeight;
    }
    return (width: width, height: height, photoHeight: photoHeight);
  }
}

class _PassLikeFabs extends ConsumerWidget {
  const _PassLikeFabs({required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verified = ref.watch(isVerifiedProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!verified) ...[
          Text(
            AppCopy.likeNeedsVerify,
            key: const ValueKey('like-needs-verify'),
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundAction(
              key: const ValueKey('pass-button'),
              size: AppSizes.passFab,
              filled: false,
              icon: Icons.close_rounded,
              tooltip: AppCopy.passTooltip,
              onTap: () => SparkActions.pass(ref, profile),
            ),
            const SizedBox(width: AppSizes.fabGap),
            _RoundAction(
              key: const ValueKey('like-button'),
              size: AppSizes.likeFab,
              filled: true,
              dimmed: !verified,
              icon: Icons.auto_awesome,
              tooltip: verified ? AppCopy.likeTooltip : AppCopy.likeNeedsVerify,
              onTap: () {
                if (!verified) {
                  promptIdentityVerification(context);
                  return;
                }
                likeAndMaybeMatch(context, ref, profile);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.size,
    required this.filled,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.dimmed = false,
  });

  final double size;
  final bool filled;
  final bool dimmed;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color iconColor;
    if (!filled) {
      fill = AppColors.surface;
      iconColor = AppColors.text;
    } else if (dimmed) {
      fill = AppColors.primary.withValues(alpha: 0.35);
      iconColor = AppColors.onPrimary.withValues(alpha: 0.8);
    } else {
      fill = AppColors.primary;
      iconColor = AppColors.onPrimary;
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: fill,
        shape: CircleBorder(
          side: filled
              ? BorderSide.none
              : const BorderSide(color: AppColors.border, width: 1.5),
        ),
        elevation: filled && !dimmed ? 3 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: filled ? 28 : 24,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.photoHeight,
    this.onTap,
  });

  final DiscoveryProfile profile;
  final double photoHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        key: ValueKey('home-card-${profile.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: photoHeight,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
                child: AspectRatio(
                  aspectRatio: AppSizes.cardPhotoAspect,
                  child: PetPhoto(
                    seed: profile.photoSeeds.first,
                    iconSize: 72,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${profile.name}  ·  ${profile.ageYears}살  ·  ${_distance(profile.distanceKm)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TagKeyWrap(keys: profile.tagKeys, limit: 3, tiny: true),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        profile.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.text,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TimeSlotChips(
                        slots: profile.preferredTimeSlots,
                        tiny: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _distance(double km) {
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }
}
