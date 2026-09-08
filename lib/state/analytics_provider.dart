import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/state/session_provider.dart';

abstract final class MeetKpi {
  static const proposalSent = 'meet_proposal_sent';
  static const proposalAccepted = 'meet_proposal_accepted';
  static const proposalCounter = 'meet_proposal_counter';
}

@immutable
class AnalyticsLog {
  const AnalyticsLog({this.events = const []});

  final List<String> events;

  AnalyticsLog tracked(String name) => AnalyticsLog(events: [...events, name]);
}

class AnalyticsNotifier extends Notifier<AnalyticsLog> {
  @override
  AnalyticsLog build() {
    ref.watch(sessionLoggedInTickProvider);
    return const AnalyticsLog();
  }

  void track(String name) {
    state = state.tracked(name);
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsLog>(
  AnalyticsNotifier.new,
);
