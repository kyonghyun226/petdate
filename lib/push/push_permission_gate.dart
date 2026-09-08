import 'package:flutter/foundation.dart';

/// When the OS / pre-prompt may run. Never at onboarding or signup.
@immutable
class PushPermissionGate {
  const PushPermissionGate({
    required this.hasAuth,
    required this.isVerified,
    required this.firstMatchSeen,
    required this.alreadyAsked,
  });

  /// Firebase Auth session. No Auth → entire push stack is a no-op.
  final bool hasAuth;

  /// `users/{uid}.verifiedAt` is present (listen/get only).
  final bool isVerified;

  /// First M01 match success has been shown.
  final bool firstMatchSeen;

  /// Pre-prompt already answered (allow or deny). Blocks re-request spam.
  final bool alreadyAsked;

  /// Optional in-app pre-prompt, then OS dialog if the user allows.
  bool get canShowPreprompt {
    if (!hasAuth) return false;
    if (!isVerified) return false;
    if (!firstMatchSeen) return false;
    if (alreadyAsked) return false;
    return true;
  }

  /// OS `requestPermission` only after a yes on the pre-prompt.
  bool get canRequestOsPermission => canShowPreprompt;
}
