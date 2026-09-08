import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/models/spark.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/theme/tokens.dart';
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
    final items = ref.watch(sparkProvider).of(_bucket);

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
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(indent: 88),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: PetPhoto(
                            seed: item.profile.photoSeeds.first,
                            circle: true,
                            iconSize: 28,
                          ),
                        ),
                        title: Text(
                          '${item.profile.name}  ·  ${item.profile.ageYears}살',
                          style: AppTypography.button,
                        ),
                        subtitle: Text(
                          switch (item.bucket) {
                            SparkBucket.received => '나를 반짝했어요',
                            SparkBucket.sent => '반짝을 보냈어요',
                            SparkBucket.matched => '매칭됐어요',
                          },
                          style: AppTypography.caption,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.tabInactive,
                        ),
                        onTap: () {
                          if (item.bucket == SparkBucket.matched) {
                            openChatRoom(context, ref, item.profile);
                          } else {
                            openProfileDetail(context, item.profile);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
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
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          for (final bucket in SparkBucket.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(bucket),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == bucket
                        ? AppColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: value == bucket
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
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
                          ? AppColors.text
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
