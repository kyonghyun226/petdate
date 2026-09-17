import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/firebase/pet_photo_storage.dart';
import 'package:petdate/screens/p_profile_wizard/p00_owner_info_step.dart';
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
  const ProfileWizardScreen({super.key, this.editing = false});

  /// Opened from 마이 to revise an existing pet card (push route, not AppPhase).
  final bool editing;

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
              if (editing) {
                Navigator.of(context).pop();
              } else {
                ref.read(sessionProvider.notifier).backFromProfile();
              }
            }
          },
        ),
        title: StepIndicator(
          current: draft.step,
          total: ProfileDraft.stepCount,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: draft.step,
              children: const [
                P00OwnerInfoStep(),
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
                label: isLast
                    ? (editing ? AppCopy.saveProfile : AppCopy.startSpark)
                    : AppCopy.next,
                onPressed: draft.currentStepValid
                    ? () async {
                        if (isLast) {
                          // Prefer Firebase Auth uid so writes bind to the
                          // signed-in account even if session.uid lagged.
                          final uid = IdentityRemote.authUid ??
                              ref.read(sessionProvider).uid;
                          if (uid == null) {
                            if (!context.mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(AppCopy.profileSaveFailed),
                              ),
                            );
                            return;
                          }

                          var saved = false;
                          Object? saveError;
                          try {
                            await IdentityVerification.ensureUserDocExists(
                              uid: uid,
                              ownerAgeBand: draft.ownerAgeBand,
                              ownerGender: draft.ownerGender,
                              dogExperience: draft.dogExperience,
                            );
                            final synced = await PetPhotoStorage.syncDraftPhotos(
                              uid: uid,
                              draft: draft,
                            );
                            ref.read(profileDraftProvider.notifier).hydrate(synced);
                            await ref
                                .read(ownPetRepositoryProvider)
                                .upsertPet(uid: uid, draft: synced);
                            saved = true;
                          } catch (error, stack) {
                            saveError = error;
                            assert(() {
                              debugPrint('Profile save failed: $error\n$stack');
                              return true;
                            }());
                          }
                          if (!context.mounted) return;
                          if (!saved) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            final detail = saveError is FirebaseException
                                ? ' (${saveError.code})'
                                : '';
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${AppCopy.profileSaveFailed}$detail',
                                ),
                              ),
                            );
                            return;
                          }
                          if (editing) {
                            Navigator.of(context).pop();
                          } else {
                            ref.read(sessionProvider.notifier).completeProfile();
                          }
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
