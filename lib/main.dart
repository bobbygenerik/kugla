import 'package:flutter/material.dart';

import 'app/app_shell.dart';

/// Splash video starts immediately; Firebase is initialized when the shell loads.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KuglaApp());
}
