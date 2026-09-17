import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local location prompt flags (do not write onto users/{uid}).
abstract class LocationPromptStore {
  bool get hasAsked;
  bool get declinedPreprompt;
  bool get osDenied;

  /// Y01 「위치 켜기」 after the user said no to the pre-prompt or OS.
  bool get shouldOfferEnableInSettings =>
      hasAsked && (declinedPreprompt || osDenied);

  Future<void> hydrate();
  Future<void> markAsked();
  Future<void> markDeclinedPreprompt();
  Future<void> markOsDenied();
  Future<void> markGranted();
}

class InMemoryLocationPromptStore implements LocationPromptStore {
  InMemoryLocationPromptStore({
    this.hasAsked = false,
    this.declinedPreprompt = false,
    this.osDenied = false,
  });

  @override
  bool hasAsked;

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

class PrefsLocationPromptStore extends InMemoryLocationPromptStore {
  PrefsLocationPromptStore();

  static const askedKey = 'banjjak.location.hasAsked';
  static const declinedKey = 'banjjak.location.declinedPreprompt';
  static const osDeniedKey = 'banjjak.location.osDenied';

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(askedKey, hasAsked);
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
      declinedPreprompt = prefs.getBool(declinedKey) ?? false;
      osDenied = prefs.getBool(osDeniedKey) ?? false;
    } on Object {
      // Keep in-memory defaults.
    }
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
class LocationPromptSnapshot {
  const LocationPromptSnapshot({
    required this.hasAsked,
    required this.shouldOfferEnableInSettings,
  });

  final bool hasAsked;
  final bool shouldOfferEnableInSettings;
}
