import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/trust_badge.dart';

/// A02 identity verification.
/// After Auth: ensure user doc → `markUserVerified` → listen `users/{uid}`.
/// Without Auth (tests / mock login): same UI, local mock unlock.
/// Client never writes `users/{uid}.verifiedAt`.
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
    final session = ref.read(sessionProvider);
    await IdentityVerification.ensureUserDocExists(
      uid: session.uid,
      goal: session.goal,
    );
    if (!mounted) return;
    // Server writes verifiedAt. Client listens — does not set the field.
    final result =
        await IdentityVerification.requestMarkVerified(uid: session.uid);
    if (!mounted) return;
    if (result != null) {
      await ref.read(userDocProvider.notifier).pullRemoteUserDoc(
            afterCallableSuccess: true,
            verifiedAtIso: result.verifiedAtIso,
          );
    }
    if (mounted) setState(() => _busy = false);
  }

  void _goSpark() {
    final session = ref.read(sessionProvider);
    if (!session.profileCompleted) {
      Navigator.of(context).pop(true);
      return;
    }
    ref.read(sessionProvider.notifier).selectTab(MainTab.home);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final verified = ref.watch(isVerifiedProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(verified),
        ),
        title: Text(verified ? AppCopy.verifyDone : AppCopy.verifyTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: verified
              ? _SuccessBody(onGo: _goSpark)
              : _PromptBody(
                  busy: _busy,
                  onConfirm: _confirm,
                ),
        ),
      ),
    );
  }
}

class _PromptBody extends StatelessWidget {
  const _PromptBody({required this.busy, required this.onConfirm});

  final bool busy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          onPressed: busy ? null : onConfirm,
        ),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.onGo});

  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.safetyBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.secondary,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(AppCopy.verifyDone, style: AppTypography.display),
        const SizedBox(height: AppSpacing.md),
        Text(AppCopy.verifySuccessBody, style: AppTypography.body),
        const SizedBox(height: AppSpacing.lg),
        const Align(
          alignment: Alignment.centerLeft,
          child: TrustBadge(compact: false),
        ),
        const Spacer(),
        PrimaryButton(
          key: const ValueKey('a02-go-spark'),
          label: AppCopy.verifyGoSpark,
          onPressed: onGo,
        ),
      ],
    );
  }
}
