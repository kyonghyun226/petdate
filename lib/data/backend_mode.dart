import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/firebase/identity_remote.dart';

/// Auth 없으면 mock, Auth 있으면 Firestore.
///
/// Widget tests and unconfigured hosts keep the in-memory catalog.
/// Override this provider to force mock even if Auth is present.
final useMockDataProvider = Provider<bool>((ref) {
  return !IdentityRemote.isLiveAuthReady;
});
