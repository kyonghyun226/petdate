import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/common.dart';

class A01LoginScreen extends ConsumerWidget {
  const A01LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const BrandMark(iconSize: 80),
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
              SocialButton(
                label: AppCopy.loginGoogle,
                leading: const _GoogleMark(),
                onPressed: () => ref.read(sessionProvider.notifier).mockLogin(),
              ),
              const SizedBox(height: AppSpacing.md),
              SocialButton(
                label: AppCopy.loginApple,
                leading: const Icon(
                  Icons.apple,
                  size: 24,
                  color: AppColors.text,
                ),
                onPressed: () => ref.read(sessionProvider.notifier).mockLogin(),
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
