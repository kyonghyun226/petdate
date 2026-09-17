import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
import 'package:petdate/location/location_host.dart';
import 'package:petdate/push/push_host.dart';
import 'package:petdate/push/push_providers.dart';
import 'package:petdate/routing/session_gate.dart';
import 'package:petdate/theme/app_theme.dart';

class PetdateApp extends ConsumerWidget {
  const PetdateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppCopy.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: ref.watch(rootNavigatorKeyProvider),
      home: const PushHost(
        child: LocationHost(child: SessionGate()),
      ),
    );
  }
}
