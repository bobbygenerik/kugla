import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app_shell.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('FIREBASE_ENABLED', defaultValue: true);
  if (enabled) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const KuglaApp());
}
