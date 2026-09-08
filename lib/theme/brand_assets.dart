/// Confirmed brand files.
///
/// When `wordmark_v3.png` lands:
/// 1. Save it as [wordmark]
/// 2. Add the path under `flutter.assets` in pubspec.yaml
/// 3. Set [hasWordmarkImage] to true
///
/// [BrandWordmark] then renders the PNG instead of the dual-tone text fallback.
abstract final class BrandAssets {
  static const appIcon = 'assets/branding/app_icon.png';

  /// Dual-tone wordmark: 반짝 coral / 산책 charcoal + coral ✦. Mint is not used.
  static const wordmark = 'assets/branding/wordmark_v3.png';

  static const hasWordmarkImage = false;

  static const wordmarkHalfSpark = '반짝';
  static const wordmarkHalfWalk = '산책';
}
