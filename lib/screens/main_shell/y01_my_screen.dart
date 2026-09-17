import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/copy/species_copy.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/firebase/owner_codec.dart';
import 'package:petdate/legal/legal_documents.dart';
import 'package:petdate/models/pet_tag.dart';
import 'package:petdate/screens/legal/legal_document_screen.dart';
import 'package:petdate/screens/y01_settings/y01_settings_screen.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/pet_photo.dart';
import 'package:petdate/widgets/trust_badge.dart';

class Y01MyScreen extends ConsumerWidget {
  const Y01MyScreen({super.key});

  void _showVerifiedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppCopy.verifyDone),
          content: const Text(AppCopy.verifyAlreadyDoneBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppCopy.close),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppCopy.deleteAccountTitle),
          content: const Text(AppCopy.deleteAccountBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppCopy.deleteAccountCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text(AppCopy.deleteAccountConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await ref.read(sessionProvider.notifier).deleteAccount();
    } on Object {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppCopy.deleteAccountFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final verified = ref.watch(isVerifiedProvider);
    final pending = ref.watch(isPetRegPendingProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        title: const Text(AppCopy.navMy),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          _PetSummaryCard(
            draft: draft,
            verified: verified,
            onTap: () => openPetProfileEdit(context, ref),
          ),
          const SizedBox(height: AppSpacing.xl),
          _MenuTile(
            icon: Icons.pets_outlined,
            label: AppCopy.verifyTitle,
            trailing: verified
                ? AppCopy.verifyStatusVerified
                : pending
                    ? AppCopy.verifyStatusPending
                    : AppCopy.verifyStatusUnverified,
            onTap: verified
                ? () => _showVerifiedDialog(context)
                : () => openIdentityVerification(context),
          ),
          _MenuTile(
            icon: Icons.description_outlined,
            label: AppCopy.myTermsOfService,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LegalDocumentScreen(
                    title: AppCopy.myTermsOfService,
                    sections: LegalDocuments.termsOfService,
                  ),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.privacy_tip_outlined,
            label: AppCopy.myPrivacyPolicy,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LegalDocumentScreen(
                    title: AppCopy.myPrivacyPolicy,
                    sections: LegalDocuments.privacyPolicy,
                  ),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            label: AppCopy.mySettings,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Y01SettingsScreen(),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: AppCopy.myLogout,
            danger: true,
            onTap: () => ref.read(sessionProvider.notifier).signOut(),
          ),
          _MenuTile(
            icon: Icons.person_off_outlined,
            label: AppCopy.myDeleteAccount,
            danger: true,
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}

class _PetSummaryCard extends StatelessWidget {
  const _PetSummaryCard({
    required this.draft,
    required this.verified,
    required this.onTap,
  });

  final ProfileDraft draft;
  final bool verified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final age = draft.displayAgeYears;
    final tags = draft.tags.take(3);
    final ownerLine = OwnerCodec.summaryLine(
      ageBand: draft.ownerAgeBand,
      gender: draft.ownerGender,
      experience: draft.dogExperience,
    );

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: PetPhoto(
                    seed: draft.primaryPhotoSeed,
                    bytes: draft.primaryPhoto?.bytes,
                    imageUrl: draft.primaryPhoto?.remoteUrl,
                    circle: true,
                    iconSize: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(draft.displayName, style: AppTypography.title),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          if (draft.breed.trim().isNotEmpty) draft.breed.trim(),
                          if (age != null) '$age살',
                          SpeciesCopy.noun(draft.species),
                        ].join(' · '),
                        style: AppTypography.caption,
                      ),
                      if (ownerLine != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${AppCopy.ownerSectionLabel} · $ownerLine',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          tags.map(PetTags.labelOf).join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      if (verified)
                        const TrustBadge()
                      else
                        Text(
                          AppCopy.verifyStatusUnverified,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.tabInactive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.text;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!, style: AppTypography.caption),
          const Icon(Icons.chevron_right_rounded, color: AppColors.tabInactive),
        ],
      ),
      onTap: onTap,
    );
  }
}
