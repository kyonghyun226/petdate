import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/screens/p_profile_wizard/p01_basic_info_step.dart';
import 'package:petdate/screens/p_profile_wizard/p02_photos_step.dart';
import 'package:petdate/screens/p_profile_wizard/p03_tags_step.dart';
import 'package:petdate/screens/p_profile_wizard/p04_bio_step.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/common.dart';

class ProfileWizardScreen extends ConsumerWidget {
  const ProfileWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final notifier = ref.read(profileDraftProvider.notifier);
    final isLast = draft.step == ProfileDraft.lastStep;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (!notifier.tryBack()) {
              ref.read(sessionProvider.notifier).backFromProfile();
            }
          },
        ),
        title: StepIndicator(current: draft.step),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: draft.step,
              children: const [
                P01BasicInfoStep(),
                P02PhotosStep(),
                P03TagsStep(),
                P04BioStep(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: PrimaryButton(
                label: isLast ? AppCopy.startSpark : AppCopy.next,
                onPressed: draft.currentStepValid
                    ? () async {
                        if (isLast) {
                          final uid = ref.read(sessionProvider).uid;
                          final goal = ref.read(sessionProvider).goal;
                          try {
                            await IdentityVerification.ensureUserDocExists(
                              uid: uid,
                              goal: goal,
                            );
                            if (uid != null) {
                              await ref
                                  .read(socialRepositoryProvider)
                                  .upsertPet(uid: uid, draft: draft);
                            }
                          } catch (_) {
                            // Offline / rules: session still advances; retry on next edit.
                          }
                          if (!context.mounted) return;
                          ref.read(sessionProvider.notifier).completeProfile();
                        } else {
                          notifier.tryNext();
                        }
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
