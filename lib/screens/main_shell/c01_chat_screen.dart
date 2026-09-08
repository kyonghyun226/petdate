import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/common.dart';
import 'package:petdate/widgets/pet_photo.dart';

class C01ChatScreen extends ConsumerWidget {
  const C01ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(chatProvider).threads;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppCopy.navChat),
        automaticallyImplyLeading: false,
      ),
      body: threads.isEmpty
          ? EmptyState(
              message: AppCopy.chatEmpty,
              hint: AppCopy.chatEmptyHint,
              icon: Icons.chat_bubble_outline_rounded,
              actionLabel: AppCopy.goHome,
              onAction: () =>
                  ref.read(sessionProvider.notifier).selectTab(MainTab.home),
            )
          : ListView.separated(
              itemCount: threads.length,
              separatorBuilder: (_, _) => const Divider(indent: 88),
              itemBuilder: (context, i) {
                final thread = threads[threads.length - 1 - i];
                final last = thread.messages.isEmpty
                    ? ''
                    : thread.messages.last.text;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: PetPhoto(
                      seed: thread.profile.photoSeeds.first,
                      circle: true,
                      iconSize: 28,
                    ),
                  ),
                  title: Text(
                    thread.profile.name,
                    style: AppTypography.button,
                  ),
                  subtitle: Text(
                    last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                  onTap: () => openChatRoom(
                    context,
                    ref,
                    thread.profile,
                  ),
                );
              },
            ),
    );
  }
}
