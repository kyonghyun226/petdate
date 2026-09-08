import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/flow/app_nav.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/screens/c03_meetup/c03_meetup_sheet.dart';
import 'package:petdate/screens/r01_report/r01_report_sheet.dart';
import 'package:petdate/state/analytics_provider.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/feed_provider.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/chips.dart';
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

  void _insertTemplate(String text) {
    _input.text = text;
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
    ref
        .read(analyticsProvider.notifier)
        .track(MeetKpi.firstMessageTemplateUsed);
    setState(() {});
  }

  Future<void> _onMenu(String value, ChatThread thread) async {
    switch (value) {
      case 'profile':
        await openProfileDetail(context, thread.profile);
      case 'report':
        if (!mounted) return;
        await showR01ReportSheet(context, thread.profile);
      case 'block':
        final uid = ref.read(sessionProvider).uid;
        ref.read(sparkProvider.notifier).block(thread.profile.id);
        ref.read(feedProvider.notifier).dismiss(thread.profile.id);
        ref.read(chatProvider.notifier).removeByProfile(thread.profile.id);
        if (uid != null) {
          await ref.read(socialRepositoryProvider).blockUser(
                blockerId: uid,
                blockedId: thread.profile.id,
              );
        }
        if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(
      chatProvider.select((s) => s.byId(widget.threadId)),
    );
    final blocked = ref.watch(sparkProvider.select((s) => s.blockedIds));
    final allowed = thread != null && !blocked.contains(thread.profile.id);

    if (!allowed) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text(AppCopy.chatMembersOnly)),
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
                '${thread.profile.name} · ${thread.profile.distanceLabel}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: AppCopy.reportMenu,
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (value) => _onMenu(value, thread),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Text(AppCopy.viewProfile),
              ),
              PopupMenuItem(
                value: 'report',
                child: Text(AppCopy.reportMenuItem),
              ),
              PopupMenuItem(
                value: 'block',
                child: Text(AppCopy.blockMenuItem),
              ),
            ],
          ),
        ],
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
              itemBuilder: (context, i) => _Bubble(
                threadId: widget.threadId,
                message: thread.messages[i],
              ),
            ),
          ),
          if (showChips)
            SizedBox(
              height: AppSizes.templateChipHeight,
              child: ListView.separated(
                key: const ValueKey('first-message-chips'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: chips.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  return TemplateChip(
                    key: ValueKey('first-message-chip-$i'),
                    label: chips[i],
                    onTap: () => _insertTemplate(chips[i]),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TemplateChip(
                key: const ValueKey('meetup-propose-chip'),
                label: AppCopy.proposeMeetup,
                leading: Icons.place_outlined,
                onTap: () => showC03MeetupSheet(context, widget.threadId),
              ),
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
                      key: const ValueKey('c02-input'),
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: AppCopy.chatInputHint,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    key: const ValueKey('c02-send'),
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
  const _Bubble({required this.threadId, required this.message});

  final String threadId;
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.kind == ChatMessageKind.meetup)
              _MeetupCard(message: message)
            else
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: mine ? AppColors.primarySoft : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  message.text,
                  style: AppTypography.body.copyWith(fontSize: 15),
                ),
              ),
            if (message.kind == ChatMessageKind.meetup && !mine)
              _InboundMeetupActions(threadId: threadId, message: message),
          ],
        ),
      ),
    );
  }
}

class _MeetupCard extends StatelessWidget {
  const _MeetupCard({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final proposal = message.proposal;
    final place = proposal == null
        ? message.text
        : MeetupCopy.placeLine(proposal);
    final time = proposal?.timeLabel ?? '';
    final memo = proposal?.memo.trim() ?? '';

    return Container(
      key: ValueKey('meetup-card-${message.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: message.isMine ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppCopy.proposeMeetup,
            style: AppTypography.button.copyWith(fontSize: 15),
          ),
          if (proposal != null) ...[
            const SizedBox(height: AppSpacing.md),
            _MeetupField(label: AppCopy.meetupPlace, value: place),
            const SizedBox(height: AppSpacing.sm),
            _MeetupField(label: AppCopy.meetupTime, value: time),
            if (memo.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(memo, style: AppTypography.caption),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                message.text,
                style: AppTypography.body.copyWith(fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeetupField extends StatelessWidget {
  const _MeetupField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _InboundMeetupActions extends ConsumerWidget {
  const _InboundMeetupActions({
    required this.threadId,
    required this.message,
  });

  final String threadId;
  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = message.receipt ?? MeetupReceipt.pending;
    if (receipt != MeetupReceipt.pending) {
      final label = switch (receipt) {
        MeetupReceipt.accepted => AppCopy.meetupAccepted,
        MeetupReceipt.countered => AppCopy.meetupCountered,
        MeetupReceipt.ignored => AppCopy.meetupIgnored,
        MeetupReceipt.pending => '',
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(label, style: AppTypography.caption),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const ValueKey('meetup-accept'),
            label: AppCopy.meetupAccept,
            onPressed: () {
              ref.read(chatProvider.notifier).setMeetupReceipt(
                    threadId,
                    message.id,
                    MeetupReceipt.accepted,
                  );
              ref
                  .read(analyticsProvider.notifier)
                  .track(MeetKpi.proposalAccepted);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            key: const ValueKey('meetup-counter'),
            label: AppCopy.meetupCounter,
            onPressed: () {
              ref.read(chatProvider.notifier).setMeetupReceipt(
                    threadId,
                    message.id,
                    MeetupReceipt.countered,
                  );
              ref
                  .read(analyticsProvider.notifier)
                  .track(MeetKpi.proposalCounter);
              showC03MeetupSheet(context, threadId);
            },
          ),
          TextButton(
            key: const ValueKey('meetup-ignore'),
            onPressed: () {
              ref.read(chatProvider.notifier).setMeetupReceipt(
                    threadId,
                    message.id,
                    MeetupReceipt.ignored,
                  );
            },
            child: Text(
              AppCopy.meetupIgnore,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
