import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'core/storage/offline_cache.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase (file storage)
  await Supabase.initialize(
    url: 'https://oflxgcsaxzauivbywmwl.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9mbHhnY3NheHphdWl2Ynl3bXdsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU1MTE1MDEsImV4cCI6MjEwMTA4NzUwMX0.VsnSm-uuVv_4P2fNK5_7fL6LHmVmt90AGtTCwoD0Pxc',
  );

  // Register background FCM message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Hive + open offline cache boxes
  await OfflineCache.init();

  runApp(
    const ProviderScope(
      child: CampusCoreApp(),
    ),
  );

  // Keep Render backend alive — ping every 10 minutes to prevent cold starts
  const pingUrl =
      'https://campuscore-bfrq.onrender.com/api/v1/departments';
  final pinger = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  Timer.periodic(const Duration(minutes: 10), (_) async {
    try {
      await pinger.get(pingUrl);
    } catch (_) {}
  });
}
