import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/data/backend_mode.dart';
import 'package:petdate/data/social_providers.dart';
import 'package:petdate/models/chat.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/chat_provider.dart';
import 'package:petdate/state/feed_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/spark_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';

abstract final class SparkActions {
  /// Like [profile]. Returns true when it becomes a match.
  ///
  /// P0: no user-doc `verifiedAt` (listen) → do not create likes/matches.
  static Future<bool> like(WidgetRef ref, DiscoveryProfile profile) async {
    if (!ref.read(isVerifiedProvider)) return false;
    final bool matched;
    if (ref.read(useMockDataProvider)) {
      matched = ref.read(sparkProvider.notifier).like(profile);
    } else {
      final uid = ref.read(sessionProvider).uid;
      if (uid == null) return false;
      matched = await ref.read(socialRepositoryProvider).sendLike(
            fromUid: uid,
            to: profile,
          );
      ref.read(sparkProvider.notifier).like(
            matched ? profile.copyWith(likedMe: true) : profile,
          );
    }
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
