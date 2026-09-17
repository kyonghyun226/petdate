import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/constants/app_constants.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/state/analytics_provider.dart';
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
      child: C03MeetupSheet(threadId: threadId),
    ),
  );
}

class C03MeetupSheet extends ConsumerStatefulWidget {
  const C03MeetupSheet({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<C03MeetupSheet> createState() => _C03MeetupSheetState();
}

class _C03MeetupSheetState extends ConsumerState<C03MeetupSheet> {
  MeetupPlace _place = MeetupPlace.park;
  String _time = AppCopy.meetupTonight;
  bool _customTime = false;
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
    return _time.isNotEmpty && _time != AppCopy.meetupPickDateTime;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;
    setState(() {
      _time = _formatPicked(date, time);
      _customTime = true;
    });
  }

  String _formatPicked(DateTime date, TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${date.month}월 ${date.day}일 $period $hour12:$minute';
  }

  void _selectTime(String label) {
    if (label == AppCopy.meetupPickDateTime) {
      _pickDateTime();
      return;
    }
    setState(() {
      _time = label;
      _customTime = false;
    });
  }

  bool _timeSelected(String label) {
    if (label == AppCopy.meetupPickDateTime) return _customTime;
    return !_customTime && _time == label;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('c03-meetup-sheet'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppCopy.meetupTitle, style: AppTypography.title),
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
              key: const ValueKey('meetup-other-place'),
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
                  key: ValueKey('meetup-time-$time'),
                  label: time == AppCopy.meetupPickDateTime && _customTime
                      ? _time
                      : time,
                  selected: _timeSelected(time),
                  onTap: () => _selectTime(time),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(AppCopy.meetupMemo, style: AppTypography.button),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('meetup-memo'),
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
            key: const ValueKey('meetup-send'),
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
                    ref
                        .read(analyticsProvider.notifier)
                        .track(MeetKpi.proposalSent);
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
