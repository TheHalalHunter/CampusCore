class ResourceModel {
  final String id;
  final String title;
  final String? description;
  final String fileUrl;
  final String? fileType;
  final int? fileSize;
  final String type;
  final String status;
  final String courseId;
  final String uploaderId;
  final String? academicYear;
  final bool isOfficial;
  final int downloadCount;

  const ResourceModel({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    this.fileType,
    this.fileSize,
    required this.type,
    required this.status,
    required this.courseId,
    required this.uploaderId,
    this.academicYear,
    required this.isOfficial,
    required this.downloadCount,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String? ?? '',
      fileType: json['fileType'] as String? ?? json['file_type'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt() ?? (json['file_size'] as num?)?.toInt(),
      type: json['type'] as String? ?? 'other',
      status: json['status'] as String? ?? 'approved',
      courseId: json['courseId'] as String? ?? json['course_id'] as String? ?? '',
      uploaderId: json['uploaderId'] as String? ?? json['uploader_id'] as String? ?? '',
      academicYear: json['academicYear'] as String? ?? json['academic_year'] as String?,
      isOfficial: json['isOfficial'] as bool? ?? json['is_official'] as bool? ?? false,
      downloadCount: (json['downloadCount'] as num?)?.toInt() ??
          (json['download_count'] as num?)?.toInt() ?? 0,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'lecture_note': return 'Lecture Note';
      case 'past_question': return 'Past Question';
      case 'slide': return 'Slide';
      case 'practical_manual': return 'Practical Manual';
      case 'assignment': return 'Assignment';
      default: return 'Resource';
    }
  }

  String get fileSizeLabel {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
