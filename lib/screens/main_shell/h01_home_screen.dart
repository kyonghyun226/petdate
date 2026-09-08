import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/widgets/common.dart';

class H01HomeScreen extends ConsumerWidget {
  const H01HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal =
        ref.watch(sessionProvider.select((s) => s.goal)) ?? UserGoal.friend;

    return Scaffold(
      appBar: AppBar(
        title: Text(GoalCopy.homeTitle(goal)),
        automaticallyImplyLeading: false,
      ),
      body: EmptyState(
        message: GoalCopy.homeEmpty(goal),
        icon: goal == UserGoal.friend
            ? Icons.pets_outlined
            : Icons.directions_walk_outlined,
      ),
    );
  }
}
