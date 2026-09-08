import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/auth/auth_repository.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';
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
                leading: const Icon(
                  Icons.apple,
                  size: 24,
                  color: AppColors.text,
                ),
                onPressed: _busy
                    ? null
                    : () => _signIn(
                          ref.read(sessionProvider.notifier).signInWithApple,
                        ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppCopy.loginTerms,
                textAlign: TextAlign.center,
                style: AppTypography.caption,
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
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1,
        color: Color(0xFF4285F4),
      ),
    );
  }
}
