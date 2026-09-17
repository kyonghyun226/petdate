import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/data/mock_profiles.dart';
import 'package:petdate/legal/legal_documents.dart';
import 'package:petdate/screens/legal/legal_document_screen.dart';
import 'package:petdate/state/profile_provider.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/common.dart';

class A01LoginScreen extends ConsumerStatefulWidget {
  const A01LoginScreen({super.key});

  @override
  ConsumerState<A01LoginScreen> createState() => _A01LoginScreenState();
}

class _A01LoginScreenState extends ConsumerState<A01LoginScreen> {
  bool _busy = false;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openLegal(
            AppCopy.myTermsOfService,
            LegalDocuments.termsOfService,
          );
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openLegal(
            AppCopy.myPrivacyPolicy,
            LegalDocuments.privacyPolicy,
          );
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _openLegal(String title, List<LegalSection> sections) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(
          title: title,
          sections: sections,
        ),
      ),
    );
  }

  void _enterGuestPreview() {
    ref.read(profileDraftProvider.notifier).hydrate(MockCatalog.guestOwnerDraft);
    ref.read(userDocProvider.notifier).applyRemoteSnapshot(
          verifiedAt: DateTime.utc(2026, 1, 1),
        );
    ref.read(sessionProvider.notifier).enterGuestPreview();
  }

  Future<void> _signIn(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AuthCancelled {
      // User dismissed the sheet — stay on A01.
    } on AuthFailure {
      _showFailure();
    } catch (_) {
      _showFailure();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showFailure() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text(AppCopy.loginFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTypography.caption.copyWith(
      color: AppColors.text,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.textMuted,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              const Spacer(),
              const BrandMark(iconSize: 88, wordmarkHeight: 40),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                AppCopy.loginTitle,
                textAlign: TextAlign.center,
                style: AppTypography.display,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppCopy.loginCaption,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(fontSize: 14),
              ),
              const Spacer(),
              if (_busy) ...[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: AppSpacing.md),
              ],
              SocialButton(
                label: AppCopy.loginGoogle,
                leading: const _GoogleMark(),
                onPressed: _busy
                    ? null
                    : () => _signIn(
                          ref.read(sessionProvider.notifier).signInWithGoogle,
                        ),
              ),
              const SizedBox(height: AppSpacing.md),
              SocialButton(
                label: AppCopy.loginApple,
                leading: const _AppleMark(),
                onPressed: _busy
                    ? null
                    : () => _signIn(
                          ref.read(sessionProvider.notifier).signInWithApple,
                        ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _busy ? null : _enterGuestPreview,
                child: Text(
                  AppCopy.loginGuestPreview,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(
                  style: AppTypography.caption,
                  children: [
                    const TextSpan(text: '계속하면 만 19세 이상이며 '),
                    TextSpan(
                      text: AppCopy.myTermsOfService,
                      style: linkStyle,
                      recognizer: _termsRecognizer,
                    ),
                    const TextSpan(text: ' 및 '),
                    TextSpan(
                      text: AppCopy.myPrivacyPolicy,
                      style: linkStyle,
                      recognizer: _privacyRecognizer,
                    ),
                    const TextSpan(text: '에 동의하는 것으로 볼게요.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/google_logo.png',
      width: 24,
      height: 24,
      fit: BoxFit.contain,
    );
  }
}

class _AppleMark extends StatelessWidget {
  const _AppleMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/apple_logo.png',
      width: 24,
      height: 24,
      fit: BoxFit.contain,
    );
  }
}
