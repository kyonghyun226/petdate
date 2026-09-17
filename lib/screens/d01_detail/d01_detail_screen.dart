import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/copy/species_copy.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/models/pet_tag.dart';
import 'package:petdate/screens/r01_report/r01_report_sheet.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/nose_provider.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/chips.dart';
import 'package:petdate/widgets/dog_nose_icon.dart';
import 'package:petdate/widgets/pet_photo.dart';
import 'package:petdate/widgets/trust_badge.dart';

class D01DetailScreen extends ConsumerStatefulWidget {
  const D01DetailScreen({
    super.key,
    required this.profile,
    this.allowMatch = true,
    this.replyToReceived = false,
    this.matchedChat = false,
  });

  final DiscoveryProfile profile;

  /// When false (멍스타 browse), show intro only — no like / match CTA.
  final bool allowMatch;

  /// B01 received → profile: CTA asks to befriend *their* pet.
  final bool replyToReceived;

  /// B01 matched → profile: optional 「대화 시작하기」 when chat not started.
  final bool matchedChat;

  @override
  ConsumerState<D01DetailScreen> createState() => _D01DetailScreenState();
}

class _D01DetailScreenState extends ConsumerState<D01DetailScreen> {
  int _page = 0;

  DiscoveryProfile get profile => widget.profile;

  @override
  Widget build(BuildContext context) {
    final verified = ref.watch(isVerifiedProvider);
    final myPetName = ref.watch(profileDraftProvider).displayName;
    final nose = ref.watch(noseProvider);
    final nosed = nose.nosed(profile.id);
    final noseCount = nose.countFor(profile);
    final thread = ref.watch(
      chatProvider.select((s) => s.byProfile(profile.id)),
    );
    final showStartChat =
        widget.matchedChat && !(thread?.conversationStarted ?? false);
    final showMatchCta = widget.allowMatch;
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
                                assetPath:
                                    i == 0 ? profile.mainPhotoAsset : null,
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
                            Positioned(
                              right: AppSpacing.lg,
                              bottom: AppSpacing.lg,
                              child: Tooltip(
                                message: AppCopy.noseGreetingTooltip,
                                child: Material(
                                  color: AppColors.surface.withValues(
                                    alpha: 0.94,
                                  ),
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.18),
                                  child: InkWell(
                                    key: const ValueKey('d01-nose'),
                                    customBorder: const CircleBorder(),
                                    onTap: () => ref
                                        .read(noseProvider.notifier)
                                        .toggle(profile.id),
                                    child: SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: Center(
                                        child: DogNoseIcon(
                                          size: 56,
                                          filled: nosed,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.name,
                                    style: AppTypography.display,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  AppCopy.noseGreetingCount(noseCount),
                                  key: const ValueKey('d01-nose-count'),
                                  style: AppTypography.caption.copyWith(
                                    color: nosed
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                const TrustBadge(),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${profile.ageYears}살 · ${profile.breed} · ${SpeciesCopy.noun(profile.species)} · ${_distance(profile.distanceKm)}',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (profile.ownerSummary != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '${AppCopy.ownerSectionLabel} · ${profile.ownerSummary}',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
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
          if (showMatchCta || showStartChat)
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
                  child: showStartChat
                      ? PrimaryButton(
                          key: const ValueKey('d01-start-chat'),
                          icon: AppIcons.spark,
                          label: AppCopy.startConversation,
                          onPressed: () async {
                            await openChatRoom(context, ref, profile);
                          },
                        )
                      : PrimaryButton(
                          key: const ValueKey('d01-cta'),
                          dimmed: !verified,
                          icon: AppIcons.spark,
                          // Same sticky slot: stream unlock swaps copy in place.
                          label: verified
                              ? (widget.replyToReceived
                                    ? AppCopy.sparkReplyCta(profile.name)
                                    : AppCopy.detailCta(myPetName))
                              : AppCopy.likeNeedsVerify,
                          onPressed: () async {
                            if (!verified) {
                              await promptIdentityVerification(context);
                              return;
                            }
                            await likeAndMaybeMatch(
                              context,
                              ref,
                              profile,
                              fromDetail: true,
                            );
                          },
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _distance(double km) => formatPetDistance(km);
}
