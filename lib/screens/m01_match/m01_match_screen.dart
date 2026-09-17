import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/push/push_providers.dart';
import 'package:petdate/screens/c02_chat_room/c02_chat_room_screen.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/pet_photo.dart';
import 'package:petdate/widgets/safety_banner.dart';

class M01MatchScreen extends ConsumerStatefulWidget {
  const M01MatchScreen({
    super.key,
    required this.profile,
    required this.threadId,
  });

  final DiscoveryProfile profile;
  final String threadId;

  @override
  ConsumerState<M01MatchScreen> createState() => _M01MatchScreenState();
}

class _M01MatchScreenState extends ConsumerState<M01MatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pushCoordinatorProvider).onFirstMatchSuccess(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(profileDraftProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              const Spacer(),
              Text(AppCopy.matchTitle, style: AppTypography.display),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CirclePhoto(
                    seed: mine.primaryPhotoSeed,
                    label: mine.displayName,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _CirclePhoto(
                    seed: widget.profile.mainPhotoSeed,
                    assetPath: widget.profile.mainPhotoAsset,
                    label: widget.profile.name,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                AppCopy.matchBody(mine.displayName, widget.profile.name),
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              const SafetyBanner(),
              const Spacer(),
              PrimaryButton(
                label: AppCopy.startChat,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          C02ChatRoomScreen(threadId: widget.threadId),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: AppCopy.later,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CirclePhoto extends StatelessWidget {
  const _CirclePhoto({
    required this.seed,
    required this.label,
    this.assetPath,
  });

  final int seed;
  final String? assetPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: PetPhoto(
              seed: seed,
              assetPath: assetPath,
              circle: true,
              iconSize: 48,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: AppTypography.button),
      ],
    );
  }
}
