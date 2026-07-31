import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize local storage
  await Hive.initFlutter();

  runApp(
    // Riverpod — wraps the entire app
    const ProviderScope(
      child: CampusCoreApp(),
    ),
  );
}
