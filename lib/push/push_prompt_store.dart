import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local prompt flags. OS permission is per-device; do not write
/// these onto `users/{uid}` (and never touch verifiedAt).
abstract class PushPromptStore {
  bool get hasAsked;
  bool get firstMatchSeen;
  bool get declinedPreprompt;
  bool get osDenied;

  /// Y01 「알림 켜기」 after the user said no to the pre-prompt or OS.
  bool get shouldOfferEnableInSettings =>
      hasAsked && (declinedPreprompt || osDenied);

  Future<void> hydrate();
  Future<void> markFirstMatchSeen();
  Future<void> markAsked();
  Future<void> markDeclinedPreprompt();
  Future<void> markOsDenied();
  Future<void> markGranted();
}

class InMemoryPushPromptStore implements PushPromptStore {
  InMemoryPushPromptStore({
    this.hasAsked = false,
    this.firstMatchSeen = false,
    this.declinedPreprompt = false,
    this.osDenied = false,
  });

  @override
  bool hasAsked;

  @override
  bool firstMatchSeen;

  @override
  bool declinedPreprompt;

  @override
  bool osDenied;

  @override
  bool get shouldOfferEnableInSettings =>
      hasAsked && (declinedPreprompt || osDenied);

  @override
  Future<void> hydrate() async {}

  @override
  Future<void> markFirstMatchSeen() async {
    firstMatchSeen = true;
  }

  @override
  Future<void> markAsked() async {
    hasAsked = true;
  }

  @override
  Future<void> markDeclinedPreprompt() async {
    hasAsked = true;
    declinedPreprompt = true;
  }

  @override
  Future<void> markOsDenied() async {
    hasAsked = true;
    osDenied = true;
  }

  @override
  Future<void> markGranted() async {
    hasAsked = true;
    declinedPreprompt = false;
    osDenied = false;
  }
}

/// Survives restarts so the first-match pre-prompt is not shown again.
class PrefsPushPromptStore extends InMemoryPushPromptStore {
  PrefsPushPromptStore();

  static const askedKey = 'banjjak.push.hasAsked';
  static const firstMatchKey = 'banjjak.push.firstMatchSeen';
  static const declinedKey = 'banjjak.push.declinedPreprompt';
  static const osDeniedKey = 'banjjak.push.osDenied';

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(askedKey, hasAsked);
      await prefs.setBool(firstMatchKey, firstMatchSeen);
      await prefs.setBool(declinedKey, declinedPreprompt);
      await prefs.setBool(osDeniedKey, osDenied);
    } on Object {
      // Widget tests / hosts without the plugin.
    }
  }

  @override
  Future<void> hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      hasAsked = prefs.getBool(askedKey) ?? false;
      firstMatchSeen = prefs.getBool(firstMatchKey) ?? false;
      declinedPreprompt = prefs.getBool(declinedKey) ?? false;
      osDenied = prefs.getBool(osDeniedKey) ?? false;
    } on Object {
      // Keep in-memory defaults.
    }
  }

  @override
  Future<void> markFirstMatchSeen() async {
    await super.markFirstMatchSeen();
    await _persist();
  }

  @override
  Future<void> markAsked() async {
    await super.markAsked();
    await _persist();
  }

  @override
  Future<void> markDeclinedPreprompt() async {
    await super.markDeclinedPreprompt();
    await _persist();
  }

  @override
  Future<void> markOsDenied() async {
    await super.markOsDenied();
    await _persist();
  }

  @override
  Future<void> markGranted() async {
    await super.markGranted();
    await _persist();
  }
}

@immutable
class PushPromptSnapshot {
  const PushPromptSnapshot({
    required this.hasAsked,
    required this.shouldOfferEnableInSettings,
  });

  final bool hasAsked;
  final bool shouldOfferEnableInSettings;
}
