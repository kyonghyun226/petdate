import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/flow/spark_actions.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/feed_provider.dart';
import 'package:petdate/state/session_provider.dart';
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
      appBar: AppBar(
        title: Text(GoalCopy.homeTitle(goal)),
        automaticallyImplyLeading: false,
      ),
      body: current == null
          ? EmptyState(
              message: GoalCopy.homeEmpty(goal),
              icon: goal == UserGoal.friend
                  ? Icons.pets_outlined
                  : Icons.directions_walk_outlined,
              actionLabel: AppCopy.refresh,
              onAction: ref.read(feedProvider.notifier).refresh,
            )
          : _CardStack(profile: current, next: _peekNext(feed.remaining)),
    );
  }

  DiscoveryProfile? _peekNext(List<DiscoveryProfile> remaining) {
    if (remaining.length < 2) return null;
    return remaining[1];
  }
}

class _CardStack extends StatelessWidget {
  const _CardStack({required this.profile, this.next});

  final DiscoveryProfile profile;
  final DiscoveryProfile? next;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth - AppSpacing.xxl;
              final height = constraints.maxHeight;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (next != null)
                    Transform.translate(
                      offset: const Offset(0, 10),
                      child: Transform.scale(
                        scale: 0.96,
                        child: Opacity(
                          opacity: 0.55,
                          child: IgnorePointer(
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: _ProfileCard(profile: next!),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: width,
                    height: height,
                    child: _ProfileCard(
                      profile: profile,
                      onTap: () => openProfileDetail(context, profile),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: _PassLikeRow(profile: profile),
        ),
      ],
    );
  }
}

class _PassLikeRow extends ConsumerWidget {
  const _PassLikeRow({required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundAction(
          key: const ValueKey('pass-button'),
          size: 56,
          filled: false,
          icon: Icons.close_rounded,
          tooltip: AppCopy.passTooltip,
          onTap: () => SparkActions.pass(ref, profile),
        ),
        const SizedBox(width: 24),
        _RoundAction(
          key: const ValueKey('like-button'),
          size: 64,
          filled: true,
          icon: Icons.auto_awesome,
          tooltip: AppCopy.likeTooltip,
          onTap: () => likeAndMaybeMatch(context, ref, profile),
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
  });

  final double size;
  final bool filled;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.primary : AppColors.surface,
        shape: CircleBorder(
          side: filled
              ? BorderSide.none
              : const BorderSide(color: AppColors.border, width: 1.5),
        ),
        elevation: filled ? 2 : 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.35),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: filled ? 28 : 24,
              color: filled ? AppColors.onPrimary : AppColors.text,
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
    this.onTap,
  });

  final DiscoveryProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          key: ValueKey('home-card-${profile.id}'),
          onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 62,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.card),
                  ),
                  child: PetPhoto(
                    seed: profile.photoSeeds.first,
                    iconSize: 72,
                  ),
                ),
              ),
              Expanded(
                flex: 38,
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
