/// Demo catalog for home / spark / chat (App Store review / UI preview).
///
/// My-page profile always comes from the signed-in account's saved pet,
/// except guest preview (`uid == [uid]`) which uses [MockCatalog.guestOwnerDraft].
///
/// Enable for everyone with `--dart-define=DEMO_UI=true`, via review-demo
/// accounts, or [SessionNotifier.enterGuestPreview] (login without Auth).
abstract final class DemoMode {
  static bool _enabled = const bool.fromEnvironment(
    'DEMO_UI',
    defaultValue: false,
  );

  static bool get enabled => _enabled;

  /// Call from test bootstrap so splash still walks onboarding.
  static void disableForTests() => _enabled = false;

  /// Synthetic uid used only when [enabled] with no Auth session.
  static const uid = 'demo';

  /// Accounts that see MockCatalog on home / spark / chat after login.
  static const reviewDemoEmails = {
    'kyonghyun226@gmail.com',
  };

  static const reviewDemoUids = {
    '1FjLnLtQVNQzjhjkEUf3gkvXV063',
  };

  static bool isReviewDemoAccount({String? uid, String? email}) {
    if (uid != null && reviewDemoUids.contains(uid)) return true;
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return reviewDemoEmails.contains(normalized);
  }
}
