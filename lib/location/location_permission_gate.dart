import 'package:flutter/foundation.dart';

/// When the in-app location pre-prompt / OS dialog may run.
///
/// Ask on first entry to main (profile exists) — not at splash/login/signup.
@immutable
class LocationPermissionGate {
  const LocationPermissionGate({
    required this.hasAuth,
    required this.onMain,
    required this.alreadyAsked,
  });

  final bool hasAuth;
  final bool onMain;
  final bool alreadyAsked;

  bool get canShowPreprompt {
    if (!hasAuth) return false;
    if (!onMain) return false;
    if (alreadyAsked) return false;
    return true;
  }

  bool get canRequestOsPermission => canShowPreprompt;
}
