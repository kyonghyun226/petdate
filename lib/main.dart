import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petdate/app.dart';
import 'package:petdate/firebase_options.dart';
import 'package:petdate/push/push_messaging.dart';

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
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } on Object {
    // Unconfigured platforms (web/desktop) or analyzer/test hosts.
  }
}
