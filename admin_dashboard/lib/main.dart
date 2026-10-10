import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://oflxgcsaxzauivbywmwl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9mbHhnY3NheHphdWl2Ynl3bXdsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU1MTE1MDEsImV4cCI6MjEwMTA4NzUwMX0.VsnSm-uuVv_4P2fNK5_7fL6LHmVmt90AGtTCwoD0Pxc',
  );
  runApp(const ProviderScope(child: CampusCoreAdminApp()));
}
