import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/feed_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/common.dart';
import 'package:petdate/widgets/main_tab_app_bar.dart';
import 'package:petdate/widgets/pet_photo.dart';

/// Explore-style feed of registered dogs' main photos (Pinterest layout).
class MeongstarScreen extends ConsumerWidget {
  const MeongstarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(feedProvider.select((s) => s.catalog));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const MainTabAppBar(title: AppCopy.navMeongstar),
      body: catalog.isEmpty
          ? const EmptyState(
              message: AppCopy.meongstarEmpty,
              icon: Icons.grid_view_rounded,
            )
          : _MasonryGrid(profiles: catalog),
    );
  }
}

class _MasonryGrid extends StatelessWidget {
  const _MasonryGrid({required this.profiles});

  final List<DiscoveryProfile> profiles;

  static const _gap = AppSpacing.sm;
  static const _padding = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final left = <DiscoveryProfile>[];
    final right = <DiscoveryProfile>[];
    for (var i = 0; i < profiles.length; i++) {
      if (i.isEven) {
        left.add(profiles[i]);
      } else {
        right.add(profiles[i]);
      }
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(_padding, _padding, _padding, _padding),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Column(profiles: left)),
                const SizedBox(width: _gap),
                Expanded(child: _Column(profiles: right)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.profiles});

  final List<DiscoveryProfile> profiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < profiles.length; i++) ...[
          if (i > 0) const SizedBox(height: _MasonryGrid._gap),
          _Tile(profile: profiles[i]),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.profile});

  final DiscoveryProfile profile;

  /// Varied aspect ratios so the grid reads like a Pinterest masonry wall.
  static const _ratios = [0.72, 0.9, 1.05, 0.8, 1.2, 0.95];

  @override
  Widget build(BuildContext context) {
    final seed = profile.mainPhotoSeed;
    final aspect = _ratios[seed % _ratios.length];

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('meongstar-tile-${profile.id}'),
        onTap: () => openProfileDetail(context, profile, allowMatch: false),
        child: AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PetPhoto(
                seed: seed,
                assetPath: profile.mainPhotoAsset,
                iconSize: 48,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
