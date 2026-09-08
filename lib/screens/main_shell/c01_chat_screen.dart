import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/common.dart';
import 'package:petdate/widgets/pet_photo.dart';

class C01ChatScreen extends ConsumerWidget {
  const C01ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(sparkProvider.select((s) => s.blockedIds));
    final uid = ref.watch(sessionProvider.select((s) => s.uid));
    final threads = ref.watch(chatProvider).visible(blocked, myUid: uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppCopy.navChat),
        automaticallyImplyLeading: false,
      ),
      body: threads.isEmpty
          ? EmptyState(
              message: AppCopy.chatEmpty,
              icon: Icons.chat_bubble_outline_rounded,
              actionLabel: AppCopy.goHome,
              outlineAction: true,
              onAction: () =>
                  ref.read(sessionProvider.notifier).selectTab(MainTab.home),
            )
          : ListView.builder(
              itemCount: threads.length,
              itemBuilder: (context, i) {
                final thread = threads[i];
                return _ChatRow(
                  thread: thread,
                  onTap: () => openChatRoom(context, ref, thread.profile),
                );
              },
            ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          key: ValueKey('chat-row-${thread.profile.id}'),
          height: AppSizes.chatRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: AppSizes.chatThumb,
                height: AppSizes.chatThumb,
                child: PetPhoto(
                  seed: thread.profile.photoSeeds.first,
                  circle: true,
                  iconSize: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      thread.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    thread.timeLabel(),
                    style: AppTypography.caption,
                  ),
                  if (thread.unread) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      key: ValueKey('chat-unread-${thread.profile.id}'),
                      width: AppSizes.chatUnreadDot,
                      height: AppSizes.chatUnreadDot,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
