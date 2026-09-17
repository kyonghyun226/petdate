import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/models/discovery_profile.dart';
import 'package:petdate/state/session_provider.dart';

@immutable
class NoseState {
  const NoseState({this.nosedIds = const {}});

  final Set<String> nosedIds;

  bool nosed(String profileId) => nosedIds.contains(profileId);

  /// Display count: base from profile + 1 when I have greeted.
  int countFor(DiscoveryProfile profile) =>
      profile.noseCount + (nosed(profile.id) ? 1 : 0);

  NoseState copyWith({Set<String>? nosedIds}) =>
      NoseState(nosedIds: nosedIds ?? this.nosedIds);
}

class NoseNotifier extends Notifier<NoseState> {
  @override
  NoseState build() {
    ref.watch(sessionLoggedInTickProvider);
    return const NoseState();
  }

  /// Toggle my 「코인사」 on [profileId]. Returns whether it is now nosed.
  bool toggle(String profileId) {
    final next = {...state.nosedIds};
    final nowNosed = !next.contains(profileId);
    if (nowNosed) {
      next.add(profileId);
    } else {
      next.remove(profileId);
    }
    state = NoseState(nosedIds: next);
    return nowNosed;
  }
}

final noseProvider = NotifierProvider<NoseNotifier, NoseState>(NoseNotifier.new);
