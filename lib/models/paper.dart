class Paper {
  final int id;
  final String title;
  final String subject;
  final int grade;
  final int year;
  final String fileUrl;
  final String downloadUrl;
  final String? createdAt;
  final int? fileSize;
  final String? mimeType;

  Paper({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.year,
    required this.fileUrl,
    required this.downloadUrl,
    this.createdAt,
    this.fileSize,
    this.mimeType,
  });

  factory Paper.fromJson(Map<String, dynamic> json) {
    return Paper(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      grade: json['grade'] is int
          ? json['grade']
          : int.tryParse(json['grade'].toString()) ?? 0,
      year: json['year'] is int
          ? json['year']
          : int.tryParse(json['year'].toString()) ?? 0,
      fileUrl: json['file_url'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      createdAt: json['created_at'],
      fileSize: json['file_size'] is int
          ? json['file_size']
          : int.tryParse(json['file_size']?.toString() ?? ''),
      mimeType: json['mime_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'grade': grade,
      'year': year,
      'file_url': fileUrl,
      'download_url': downloadUrl,
      'created_at': createdAt,
      'file_size': fileSize,
      'mime_type': mimeType,
    };
  }

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown size';
    final bytes = fileSize!;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  bool get isPdf {
    return mimeType?.toLowerCase().contains('pdf') ??
        downloadUrl.toLowerCase().contains('.pdf') ||
        fileUrl.toLowerCase().contains('.pdf');
  }
}
