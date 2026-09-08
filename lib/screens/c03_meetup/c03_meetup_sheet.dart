import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/common.dart';

Future<void> showC03MeetupSheet(BuildContext context, String threadId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheetTop),
      ),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _C03MeetupSheet(threadId: threadId),
    ),
  );
}

class _C03MeetupSheet extends ConsumerStatefulWidget {
  const _C03MeetupSheet({required this.threadId});

  final String threadId;

  @override
  ConsumerState<_C03MeetupSheet> createState() => _C03MeetupSheetState();
}

class _C03MeetupSheetState extends ConsumerState<_C03MeetupSheet> {
  MeetupPlace _place = MeetupPlace.park;
  String _time = AppCopy.meetupTimeChips.first;
  final _other = TextEditingController();
  final _memo = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    _memo.dispose();
    super.dispose();
  }

  bool get _canSend {
    if (_place == MeetupPlace.other && _other.text.trim().isEmpty) {
      return false;
    }
    return _time.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppCopy.proposeMeetup, style: AppTypography.title),
          const SizedBox(height: AppSpacing.xl),
          Text(AppCopy.meetupPlace, style: AppTypography.button),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final place in MeetupPlace.values)
                SelectableChip(
                  label: MeetupPlaceCopy.label(place),
                  selected: _place == place,
                  onTap: () => setState(() => _place = place),
                ),
            ],
          ),
          if (_place == MeetupPlace.other) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _other,
              decoration: const InputDecoration(
                hintText: AppCopy.meetupOtherHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(AppCopy.meetupTime, style: AppTypography.button),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final time in AppCopy.meetupTimeChips)
                SelectableChip(
                  label: time,
                  selected: _time == time,
                  onTap: () => setState(() => _time = time),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(AppCopy.meetupMemo, style: AppTypography.button),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _memo,
            maxLines: 3,
            maxLength: AppConstants.meetupMemoMax,
            decoration: const InputDecoration(
              hintText: AppCopy.meetupMemoHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: AppCopy.send,
            onPressed: _canSend
                ? () {
                    ref.read(chatProvider.notifier).sendMeetup(
                          widget.threadId,
                          MeetupProposal(
                            place: _place,
                            placeDetail: _other.text,
                            timeLabel: _time,
                            memo: _memo.text,
                          ),
                        );
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text(AppCopy.meetupSent)),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
