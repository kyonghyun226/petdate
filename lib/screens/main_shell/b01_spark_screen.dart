import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/models/spark.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/chips.dart';
import 'package:petdate/widgets/common.dart';
import 'package:petdate/widgets/pet_photo.dart';

class B01SparkScreen extends ConsumerStatefulWidget {
  const B01SparkScreen({super.key});

  @override
  ConsumerState<B01SparkScreen> createState() => _B01SparkScreenState();
}

class _B01SparkScreenState extends ConsumerState<B01SparkScreen> {
  SparkBucket _bucket = SparkBucket.received;

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(sessionProvider.select((s) => s.mainTab));
    final items = ref.watch(sparkProvider).of(_bucket);

    if (tab == MainTab.spark && _bucket == SparkBucket.received) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(sparkProvider.notifier).markReceivedSeen();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppCopy.navSpark),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: _Segment(
              value: _bucket,
              onChanged: (v) => setState(() => _bucket = v),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    message: switch (_bucket) {
                      SparkBucket.received => AppCopy.sparkEmpty,
                      SparkBucket.sent => AppCopy.sparkSentEmpty,
                      SparkBucket.matched => AppCopy.sparkMatchedEmpty,
                    },
                    icon: Icons.auto_awesome_outlined,
                    actionLabel: _bucket == SparkBucket.sent
                        ? null
                        : AppCopy.goHome,
                    onAction: _bucket == SparkBucket.sent
                        ? null
                        : () => ref
                              .read(sessionProvider.notifier)
                              .selectTab(MainTab.home),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return _SparkRow(
                        item: item,
                        onOpen: () => _openRow(item),
                        onReply: item.bucket == SparkBucket.received
                            ? () => _reply(item)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRow(SparkItem item) async {
    if (item.bucket == SparkBucket.matched) {
      await openChatRoom(context, ref, item.profile);
      return;
    }
    await openProfileDetail(context, item.profile);
  }

  Future<void> _reply(SparkItem item) async {
    await likeAndMaybeMatch(context, ref, item.profile);
    if (!mounted) return;
    final current = ref.read(sparkProvider).byProfile(item.profile.id);
    if (current?.bucket == SparkBucket.matched) {
      setState(() => _bucket = SparkBucket.matched);
    }
  }
}

class _SparkRow extends StatelessWidget {
  const _SparkRow({required this.item, required this.onOpen, this.onReply});

  final SparkItem item;
  final VoidCallback onOpen;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          key: ValueKey('spark-row-${item.profile.id}'),
          height: AppSizes.sparkRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: AppSizes.sparkThumb,
                height: AppSizes.sparkThumb,
                child: PetPhoto(
                  seed: item.profile.photoSeeds.first,
                  circle: true,
                  iconSize: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.metaCaption(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (onReply != null)
                SparkReplyChip(
                  key: ValueKey('spark-reply-${item.profile.id}'),
                  onTap: onReply!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.value, required this.onChanged});

  final SparkBucket value;
  final ValueChanged<SparkBucket> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.sparkSegmentHeight,
      child: Row(
        children: [
          for (final bucket in SparkBucket.values)
            Expanded(
              child: GestureDetector(
                key: ValueKey('spark-segment-${bucket.name}'),
                onTap: () => onChanged(bucket),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == bucket
                        ? AppColors.primarySoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    switch (bucket) {
                      SparkBucket.received => AppCopy.sparkReceived,
                      SparkBucket.sent => AppCopy.sparkSent,
                      SparkBucket.matched => AppCopy.sparkMatched,
                    },
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: value == bucket
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
