class DocumentModel {
  final String id;
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final int pageCount;
  final DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.pageCount,
    required this.createdAt,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      fileExtension: json['fileExtension'] ?? '',
      fileSizeBytes: json['fileSizeBytes'] ?? 0,
      pageCount: json['pageCount'] ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
