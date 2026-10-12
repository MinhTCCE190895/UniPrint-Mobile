import 'package:intl/intl.dart';

class DocumentModel {
  final String id;
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final int pageCount;
  final DateTime createdAt;
  final String? userId;

  DocumentModel({
    required this.id,
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.pageCount,
    required this.createdAt,
    this.userId,
  });

  bool get isPdf => fileExtension.toLowerCase().contains('pdf');
  bool get isWord =>
      fileExtension.toLowerCase().contains('doc') ||
      fileExtension.toLowerCase().contains('docx');

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  bool isOwner(String? currentUserId) {
    if (userId == null || userId!.isEmpty) return true;
    if (currentUserId == null || currentUserId.isEmpty) return true;
    return userId == currentUserId;
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName'] ?? '',
      fileExtension: json['fileExtension'] ?? '',
      fileSizeBytes: json['fileSizeBytes'] is num
          ? (json['fileSizeBytes'] as num).toInt()
          : int.tryParse(json['fileSizeBytes']?.toString() ?? '0') ?? 0,
      pageCount: json['pageCount'] is num
          ? (json['pageCount'] as num).toInt()
          : int.tryParse(json['pageCount']?.toString() ?? '1') ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userId: json['userId']?.toString() ??
          json['uploadedBy']?.toString() ??
          json['ownerId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'fileSizeBytes': fileSizeBytes,
      'pageCount': pageCount,
      'createdAt': createdAt.toIso8601String(),
      if (userId != null) 'userId': userId,
    };
  }
}
