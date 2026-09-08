import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';

class S02OnboardingScreen extends ConsumerStatefulWidget {
  const S02OnboardingScreen({super.key});

  @override
  ConsumerState<S02OnboardingScreen> createState() => _S02OnboardingScreenState();
}

class _S02OnboardingScreenState extends ConsumerState<S02OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _icons = [
    Icons.pets_rounded,
    Icons.auto_awesome,
    Icons.park_outlined,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = AppCopy.onboardingPages;
    final isLast = _index == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = pages[i];
                    return Column(
                      children: [
                        const Spacer(),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Icon(
                            _icons[i],
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppTypography.display,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: isLast ? AppCopy.onboardingStart : AppCopy.next,
                onPressed: () {
                  if (isLast) {
                    ref.read(sessionProvider.notifier).completeOnboarding();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref.read(sessionProvider.notifier).goToLogin(),
                child: Text(
                  AppCopy.alreadyHaveAccount,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMuted,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
