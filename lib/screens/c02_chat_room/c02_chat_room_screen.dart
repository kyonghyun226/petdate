import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/screens/c03_meetup/c03_meetup_sheet.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/pet_photo.dart';
import 'package:petdate/widgets/safety_banner.dart';

class C02ChatRoomScreen extends ConsumerStatefulWidget {
  const C02ChatRoomScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<C02ChatRoomScreen> createState() => _C02ChatRoomScreenState();
}

class _C02ChatRoomScreenState extends ConsumerState<C02ChatRoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(
      chatProvider.select((s) => s.byId(widget.threadId)),
    );
    if (thread == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('대화를 찾을 수 없어요')),
      );
    }

    final goal =
        ref.watch(sessionProvider.select((s) => s.goal)) ?? UserGoal.friend;
    final myPet = ref.watch(profileDraftProvider).displayName;
    final showChips = thread.outboundCount == 0;
    final chips = GoalCopy.firstMessageChips(goal, myPet);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: PetPhoto(
                seed: thread.profile.photoSeeds.first,
                circle: true,
                iconSize: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                thread.profile.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SafetyBanner(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  AppCopy.proposeMeetup,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.primarySoft,
                side: BorderSide.none,
                onPressed: () => showC03MeetupSheet(context, widget.threadId),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              itemCount: thread.messages.length,
              itemBuilder: (context, i) => _Bubble(message: thread.messages[i]),
            ),
          ),
          if (showChips)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  return ActionChip(
                    label: Text(
                      chips[i],
                      style: AppTypography.caption.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    backgroundColor: AppColors.surfaceMuted,
                    side: BorderSide.none,
                    onPressed: () {
                      _input.text = chips[i];
                      _input.selection = TextSelection.collapsed(
                        offset: _input.text.length,
                      );
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '메시지 보내기',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: _input.text.trim().isEmpty
                        ? null
                        : () {
                            ref
                                .read(chatProvider.notifier)
                                .sendText(widget.threadId, _input.text);
                            _input.clear();
                            setState(() {});
                          },
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.35),
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.kind == ChatMessageKind.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
      );
    }

    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primarySoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(message.text, style: AppTypography.body.copyWith(fontSize: 15)),
      ),
    );
  }
}
