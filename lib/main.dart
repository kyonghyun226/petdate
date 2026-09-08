import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/app.dart';
import 'package:petdate/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const ProviderScope(child: PetdateApp()));
}

/// Android/iOS use generated [DefaultFirebaseOptions]. Other platforms and
/// widget tests continue without Firebase.
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object {
    // Unconfigured platforms (web/desktop) or analyzer/test hosts.
  }
}
