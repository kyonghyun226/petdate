/// Confirmed brand files for S01 / A01 and the launcher source.
///
/// Wordmark v3 is dual-tone (반짝 coral / 산책 charcoal) plus a coral ✦.
/// Mint sparkles belong only on [appIcon], not the wordmark.
abstract final class BrandAssets {
  static const appIcon = 'assets/branding/app_icon.png';

  /// Dual-tone wordmark: 반짝 coral / 산책 charcoal + coral ✦. Mint is not used.
  static const wordmark = 'assets/branding/wordmark_v3.png';

  /// Outline dog-nose for 「코인사」.
  static const nose = 'assets/nose.png';

  /// Filled (black) dog-nose when 코인사 is active.
  static const noseFilled = 'assets/nose_filled.png';

  static const hasWordmarkImage = true;

  static const wordmarkHalfSpark = '반짝';
  static const wordmarkHalfWalk = '산책';
}
