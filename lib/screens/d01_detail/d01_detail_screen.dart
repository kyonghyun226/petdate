import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/copy/species_copy.dart';
import 'package:petdate/flow/spark_actions.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/pet_tag.dart';
import 'package:petdate/screens/m01_match/m01_match_screen.dart';
import 'package:petdate/screens/r01_report/r01_report_sheet.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/chips.dart';
import 'package:petdate/widgets/pet_photo.dart';

class D01DetailScreen extends ConsumerStatefulWidget {
  const D01DetailScreen({super.key, required this.profile});

  final DiscoveryProfile profile;

  @override
  ConsumerState<D01DetailScreen> createState() => _D01DetailScreenState();
}

class _D01DetailScreenState extends ConsumerState<D01DetailScreen> {
  int _page = 0;

  DiscoveryProfile get profile => widget.profile;

  @override
  Widget build(BuildContext context) {
    final goal =
        ref.watch(sessionProvider.select((s) => s.goal)) ?? UserGoal.friend;
    final photos =
        profile.photoSeeds.isEmpty ? const [0] : profile.photoSeeds;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  actions: [
                    IconButton(
                      tooltip: AppCopy.reportMenu,
                      icon: const Icon(Icons.more_horiz_rounded),
                      onPressed: () => showR01ReportSheet(context, profile),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Stack(
                          children: [
                            PageView.builder(
                              itemCount: photos.length,
                              onPageChanged: (i) => setState(() => _page = i),
                              itemBuilder: (context, i) => PetPhoto(
                                seed: photos[i],
                                iconSize: 96,
                              ),
                            ),
                            if (photos.length > 1)
                              Positioned(
                                bottom: AppSpacing.md,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0; i < photos.length; i++)
                                      Container(
                                        width: i == _page ? 16 : 6,
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: i == _page
                                              ? AppColors.primary
                                              : AppColors.onPrimary
                                                  .withValues(alpha: 0.7),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.chip,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.xl,
                          AppSpacing.xl,
                          AppSpacing.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: AppTypography.display,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${profile.ageYears}살 · ${profile.breed} · ${SpeciesCopy.noun(profile.species)} · ${_distance(profile.distanceKm)}',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final key in profile.tagKeys)
                                  TagChip(label: PetTags.labelOf(key)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(profile.bio, style: AppTypography.body),
                            const SizedBox(height: AppSpacing.lg),
                            TimeSlotChips(slots: profile.preferredTimeSlots),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.surface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: PrimaryButton(
                  key: const ValueKey('d01-cta'),
                  label: GoalCopy.detailCta(goal, profile.name),
                  onPressed: () async {
                    final matched = SparkActions.like(ref, profile);
                    if (!context.mounted) return;
                    if (matched) {
                      final thread = ref
                          .read(chatProvider.notifier)
                          .ensureMatchThread(profile);
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          fullscreenDialog: true,
                          builder: (_) => M01MatchScreen(
                            profile: profile,
                            threadId: thread.id,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _distance(double km) {
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }
}
