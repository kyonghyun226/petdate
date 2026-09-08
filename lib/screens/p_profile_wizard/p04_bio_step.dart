import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';

class P04BioStep extends ConsumerStatefulWidget {
  const P04BioStep({super.key});

  @override
  ConsumerState<P04BioStep> createState() => _P04BioStepState();
}

class _P04BioStepState extends ConsumerState<P04BioStep> {
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    _bio = TextEditingController(text: ref.read(profileDraftProvider).bio);
  }

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(profileDraftProvider);
    final goal = ref.watch(sessionProvider.select((s) => s.goal)) ??
        UserGoal.friend;

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
        Text(AppCopy.p04Title, style: AppTypography.display),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _bio,
          maxLines: 5,
          maxLength: AppCopy.bioMax,
          onChanged: ref.read(profileDraftProvider.notifier).setBio,
          decoration: InputDecoration(
            hintText: GoalCopy.bioPlaceholder(goal),
            counterText: '${draft.bio.length}/${AppCopy.bioMax}',
            alignLabelWithHint: true,
          ),
        ),
        ],
      ),
    );
  }
}
