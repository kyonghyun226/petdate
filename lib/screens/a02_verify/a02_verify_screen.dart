import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';

/// A02 identity verification. Success mirrors `users/{uid}.verifiedAt`
/// after callable [IdentityContract.confirmIdentityCallable] (mocked).
class A02VerifyScreen extends ConsumerStatefulWidget {
  const A02VerifyScreen({super.key});

  @override
  ConsumerState<A02VerifyScreen> createState() => _A02VerifyScreenState();
}

class _A02VerifyScreenState extends ConsumerState<A02VerifyScreen> {
  bool _busy = false;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    final uid = ref.read(sessionProvider).uid;
    final at = await IdentityVerification.confirmIdentityMock(uid: uid);
    if (!mounted) return;
    ref.read(sessionProvider.notifier).applyVerifiedAt(at);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(AppCopy.verifyTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(AppCopy.verifyTitle, style: AppTypography.display),
              const SizedBox(height: AppSpacing.md),
              Text(AppCopy.verifyBody, style: AppTypography.body),
              const Spacer(),
              PrimaryButton(
                key: const ValueKey('a02-confirm'),
                label: AppCopy.verifyCta,
                onPressed: _busy ? null : _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
