import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/theme/tokens.dart';

class P02PhotosStep extends ConsumerWidget {
  const P02PhotosStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final notifier = ref.read(profileDraftProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(AppCopy.p02Title, style: AppTypography.display),
        const SizedBox(height: AppSpacing.md),
        Text(AppCopy.photoGuide, style: AppTypography.body),
        const SizedBox(height: AppSpacing.xs),
        Text(AppCopy.photoRequiredHint, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            for (var i = 0; i < ProfileDraft.maxPhotos; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PhotoSlot(
                  index: i,
                  photo: i < draft.photos.length ? draft.photos[i] : null,
                  isPrimary: i < draft.photos.length &&
                      draft.photos[i].id == draft.primaryPhotoId,
                  canMoveLeft: i > 0 && i < draft.photos.length,
                  canMoveRight: i < draft.photos.length - 1,
                  onAdd: notifier.addMockPhoto,
                  onRemove: i < draft.photos.length
                      ? () => notifier.removePhoto(draft.photos[i].id)
                      : null,
                  onPrimary: i < draft.photos.length
                      ? () => notifier.setPrimaryPhoto(draft.photos[i].id)
                      : null,
                  onMoveLeft: () => notifier.movePhoto(i, i - 1),
                  onMoveRight: () => notifier.movePhoto(i, i + 1),
                ),
              ),
            ],
          ],
        ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.index,
    required this.photo,
    required this.isPrimary,
    required this.canMoveLeft,
    required this.canMoveRight,
    required this.onAdd,
    required this.onRemove,
    required this.onPrimary,
    required this.onMoveLeft,
    required this.onMoveRight,
  });

  final int index;
  final MockPhoto? photo;
  final bool isPrimary;
  final bool canMoveLeft;
  final bool canMoveRight;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onPrimary;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;

  @override
  Widget build(BuildContext context) {
    final empty = photo == null;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Material(
            color: empty
                ? AppColors.surfaceMuted
                : (Color.lerp(
                      AppColors.primarySoft,
                      AppColors.secondary.withValues(alpha: 0.25),
                      (photo!.seed % 4) / 4,
                    ) ??
                    AppColors.primarySoft),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(
                color: isPrimary ? AppColors.primary : AppColors.border,
                width: isPrimary ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: empty ? onAdd : onPrimary,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      empty ? Icons.add_photo_alternate_outlined : Icons.pets,
                      color: empty ? AppColors.tabInactive : AppColors.primary,
                      size: 32,
                    ),
                  ),
                  if (isPrimary)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          AppCopy.photoPrimary,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (!empty)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        color: AppColors.text,
                        onPressed: onRemove,
                        icon: const Icon(Icons.close),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (empty)
          Text(
            index == 0 ? AppCopy.photoAdd : '${index + 1}',
            style: AppTypography.caption,
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: canMoveLeft ? onMoveLeft : null,
                child: Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: canMoveLeft ? AppColors.text : AppColors.border,
                ),
              ),
              Flexible(
                child: GestureDetector(
                  onTap: isPrimary ? null : onPrimary,
                  child: Text(
                    isPrimary ? AppCopy.photoPrimary : AppCopy.photoSetPrimary,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: isPrimary
                          ? AppColors.textMuted
                          : AppColors.primary,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: canMoveRight ? onMoveRight : null,
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: canMoveRight ? AppColors.text : AppColors.border,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
