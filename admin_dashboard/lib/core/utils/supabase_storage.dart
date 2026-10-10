import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles file uploads to Supabase Storage.
/// Bucket: Resources (public bucket created in Supabase dashboard)
class SupabaseStorageService {
  static const String _bucket = 'Resources';

  static SupabaseClient get _client => Supabase.instance.client;

  /// Upload [bytes] to [path] and return the public URL.
  static Future<String> uploadFile({
    required Uint8List bytes,
    required String path,
    required String mimeType,
  }) async {
    await _client.storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
