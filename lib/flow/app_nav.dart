import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/flow/spark_actions.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/screens/c02_chat_room/c02_chat_room_screen.dart';
import 'package:petdate/screens/d01_detail/d01_detail_screen.dart';
import 'package:petdate/screens/m01_match/m01_match_screen.dart';

Future<void> openProfileDetail(
  BuildContext context,
  DiscoveryProfile profile,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => D01DetailScreen(profile: profile),
    ),
  );
}

Future<void> openChatRoom(
  BuildContext context,
  WidgetRef ref,
  DiscoveryProfile profile,
) {
  final thread = SparkActions.ensureChat(ref, profile);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => C02ChatRoomScreen(threadId: thread.id),
    ),
  );
}

Future<void> openMatchOverlay(
  BuildContext context,
  WidgetRef ref,
  DiscoveryProfile profile, {
  bool replace = false,
}) {
  final thread = SparkActions.ensureChat(ref, profile);
  final route = MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => M01MatchScreen(
      profile: profile,
      threadId: thread.id,
    ),
  );
  if (replace) {
    return Navigator.of(context).pushReplacement(route);
  }
  return Navigator.of(context).push(route);
}

Future<void> likeAndMaybeMatch(
  BuildContext context,
  WidgetRef ref,
  DiscoveryProfile profile, {
  bool fromDetail = false,
}) async {
  final matched = SparkActions.like(ref, profile);
  if (matched) {
    if (!context.mounted) return;
    await openMatchOverlay(context, ref, profile, replace: fromDetail);
    return;
  }
  if (fromDetail && context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}
