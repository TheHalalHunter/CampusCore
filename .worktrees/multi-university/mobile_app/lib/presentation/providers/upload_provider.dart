import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/supabase_storage.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class UploadState {
  final String? filePath;
  final String? fileName;
  final Uint8List? fileBytes;
  final bool isUploading;
  final double progress;
  final String? error;

  const UploadState({
    this.filePath,
    this.fileName,
    this.fileBytes,
    this.isUploading = false,
    this.progress = 0,
    this.error,
  });

  UploadState copyWith({
    String? filePath,
    String? fileName,
    Uint8List? fileBytes,
    bool? isUploading,
    double? progress,
    String? error,
    bool clearError = false,
    bool clearFile = false,
  }) {
    return UploadState(
      filePath: clearFile ? null : (filePath ?? this.filePath),
      fileName: clearFile ? null : (fileName ?? this.fileName),
      fileBytes: clearFile ? null : (fileBytes ?? this.fileBytes),
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final uploadProvider =
    NotifierProvider<UploadNotifier, UploadState>(UploadNotifier.new);

class UploadNotifier extends Notifier<UploadState> {
  @override
  UploadState build() => const UploadState();

  /// Open file picker and store the selected file.
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx', 'doc', 'ppt'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        state = state.copyWith(
          filePath: file.path ?? file.name,
          fileName: file.name,
          fileBytes: file.bytes,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Could not open file picker: $e');
    }
  }

  void setFile(String path, String name) {
    state = state.copyWith(filePath: path, fileName: name, clearError: true);
  }

  void clearFile() {
    state = state.copyWith(clearFile: true);
  }

  /// Upload file to Supabase Storage, then submit metadata to backend.
  Future<bool> upload({
    required String title,
    required String description,
    required String type,
    required String courseId,
    String? academicYear,
  }) async {
    if (state.fileBytes == null) return false;

    state = state.copyWith(isUploading: true, progress: 0, clearError: true);

    try {
      // 1. Upload to Supabase Storage
      final fileName = state.fileName ?? 'resource.pdf';
      final storagePath =
          '$courseId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Show indeterminate progress while uploading
      state = state.copyWith(progress: 0.3);

      final downloadUrl = await SupabaseStorageService.uploadFile(
        bytes: state.fileBytes!,
        path: storagePath,
        mimeType: _contentType(fileName),
      );

      state = state.copyWith(progress: 0.7);

      // 2. Submit metadata to backend
      final api = ref.read(apiClientProvider);
      await api.post(ApiConstants.resources, data: {
        'title': title,
        'description': description.isNotEmpty ? description : null,
        'fileUrl': downloadUrl,
        'fileType': fileName.split('.').last,
        'fileSize': state.fileBytes?.length,
        'type': type,
        'courseId': courseId,
        'academicYear': academicYear,
      });

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        clearFile: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Upload failed: ${e.toString()}',
      );
      return false;
    }
  }

  String _contentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default:
        return 'application/octet-stream';
    }
  }
}
