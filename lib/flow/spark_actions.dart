import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/feed_provider.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';

abstract final class SparkActions {
  /// Like [profile]. Returns true when it becomes a match.
  ///
  /// P0: no user-doc `verifiedAt` (listen) → do not create likes/matches.
  static bool like(WidgetRef ref, DiscoveryProfile profile) {
    if (!ref.read(isVerifiedProvider)) return false;
    final matched = ref.read(sparkProvider.notifier).like(profile);
    ref.read(feedProvider.notifier).dismiss(profile.id);
    if (matched) {
      ref.read(chatProvider.notifier).ensureMatchThread(profile);
    }
    return matched;
  }

  static void pass(WidgetRef ref, DiscoveryProfile profile) {
    ref.read(feedProvider.notifier).dismiss(profile.id, passed: true);
  }

  static ChatThread ensureChat(WidgetRef ref, DiscoveryProfile profile) {
    return ref.read(chatProvider.notifier).ensureMatchThread(profile);
  }
}
