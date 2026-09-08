import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/copy/app_copy.dart';
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
      home: const SessionGate(),
    );
  }
}
