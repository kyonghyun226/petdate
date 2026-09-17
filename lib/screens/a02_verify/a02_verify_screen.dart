import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/firebase/identity_contract.dart';
import 'package:petdate/state/session_provider.dart';
import 'package:petdate/state/user_doc_provider.dart';
import 'package:petdate/theme/tokens.dart';
import 'package:petdate/widgets/buttons.dart';
import 'package:petdate/widgets/trust_badge.dart';

/// A02 pet-registration verification (manual review).
///
/// User submits owner name + registration number → `petRegStatus: pending`.
/// Operator confirms offline; Admin sets `users/{uid}.verifiedAt`.
/// Client never writes `verifiedAt`.
class A02VerifyScreen extends ConsumerStatefulWidget {
  const A02VerifyScreen({super.key});

  @override
  ConsumerState<A02VerifyScreen> createState() => _A02VerifyScreenState();
}

class _A02VerifyScreenState extends ConsumerState<A02VerifyScreen> {
  final _ownerController = TextEditingController();
  final _regController = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ownerController.dispose();
    _regController.dispose();
    super.dispose();
  }

  String? _validate() {
    final owner = _ownerController.text.trim();
    final reg = _regController.text.replaceAll(RegExp(r'\s'), '');
    if (owner.isEmpty || owner.length > 40) {
      return AppCopy.verifyInvalidOwner;
    }
    if (!RegExp(r'^\d{8,20}$').hasMatch(reg)) {
      return AppCopy.verifyInvalidReg;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final owner = _ownerController.text.trim();
    final reg = _regController.text.replaceAll(RegExp(r'\s'), '');
    try {
      final session = ref.read(sessionProvider);
      await IdentityVerification.ensureUserDocExists(uid: session.uid);
      if (!mounted) return;
      await ref.read(userDocProvider.notifier).submitPetRegistration(
            ownerName: owner,
            registrationNumber: reg,
          );
    } on Object {
      if (mounted) {
        setState(() {
          _error = AppCopy.verifySubmitFailed;
          _busy = false;
        });
      }
      return;
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
    final userDoc = ref.watch(userDocProvider);
    final verified = userDoc.isVerified;
    final pending = userDoc.isPetRegPending;

    final title = verified
        ? AppCopy.verifyDone
        : pending
            ? AppCopy.verifyPendingTitle
            : AppCopy.verifyTitle;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(verified),
        ),
        title: Text(title),
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
              : pending
                  ? _PendingBody(
                      ownerName: userDoc.petRegOwnerName,
                      registrationNumber: userDoc.petRegNumber,
                      onDone: () => Navigator.of(context).pop(false),
                    )
                  : _FormBody(
                      ownerController: _ownerController,
                      regController: _regController,
                      busy: _busy,
                      error: _error,
                      onSubmit: _submit,
                    ),
        ),
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.ownerController,
    required this.regController,
    required this.busy,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController ownerController;
  final TextEditingController regController;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;

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
            Icons.pets_rounded,
            color: AppColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(AppCopy.verifyTitle, style: AppTypography.display),
        const SizedBox(height: AppSpacing.md),
        Text(AppCopy.verifyBody, style: AppTypography.body),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          key: const ValueKey('a02-owner'),
          controller: ownerController,
          textInputAction: TextInputAction.next,
          enabled: !busy,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: AppCopy.verifyOwnerHint,
            hintText: AppCopy.verifyOwnerPlaceholder,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('a02-reg'),
          controller: regController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          enabled: !busy,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: AppCopy.verifyRegHint,
            hintText: AppCopy.verifyRegPlaceholder,
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            error!,
            style: AppTypography.caption.copyWith(color: AppColors.danger),
          ),
        ],
        const Spacer(),
        PrimaryButton(
          key: const ValueKey('a02-submit'),
          label: AppCopy.verifyCta,
          onPressed: busy ? null : onSubmit,
        ),
      ],
    );
  }
}

class _PendingBody extends StatelessWidget {
  const _PendingBody({
    required this.ownerName,
    required this.registrationNumber,
    required this.onDone,
  });

  final String? ownerName;
  final String? registrationNumber;
  final VoidCallback onDone;

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
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_top_rounded,
            color: AppColors.primary,
            size: 44,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(AppCopy.verifyPendingTitle, style: AppTypography.display),
        const SizedBox(height: AppSpacing.md),
        Text(AppCopy.verifyPendingBody, style: AppTypography.body),
        if (ownerName != null && ownerName!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${AppCopy.verifyOwnerHint}: $ownerName',
            style: AppTypography.caption,
          ),
        ],
        if (registrationNumber != null && registrationNumber!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${AppCopy.verifyRegHint}: $registrationNumber',
            style: AppTypography.caption,
          ),
        ],
        const Spacer(),
        PrimaryButton(
          key: const ValueKey('a02-pending-done'),
          label: AppCopy.later,
          onPressed: onDone,
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
          decoration: const BoxDecoration(
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
