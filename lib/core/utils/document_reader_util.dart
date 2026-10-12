import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';

class DocumentMetadata {
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final int pageCount;
  final bool isSupported;
  final String? errorMessage;

  const DocumentMetadata({
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.pageCount,
    this.isSupported = true,
    this.errorMessage,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class DocumentReaderUtil {
  static const List<String> supportedExtensions = ['pdf', 'docx', 'doc'];
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB

  /// Read metadata from a picked PlatformFile
  static Future<DocumentMetadata> readFromPlatformFile(PlatformFile pickedFile) async {
    final fileName = pickedFile.name;
    final fileExtension = _extractExtension(fileName);
    final fileSizeBytes = pickedFile.lengthSync() ?? (await pickedFile.length()) ?? 0;

    if (!_isExtensionSupported(fileExtension)) {
      return DocumentMetadata(
        fileName: fileName,
        fileExtension: fileExtension,
        fileSizeBytes: fileSizeBytes,
        pageCount: 1,
        isSupported: false,
        errorMessage: 'Hệ thống chỉ hỗ trợ tài liệu định dạng PDF hoặc DOCX/DOC.',
      );
    }

    if (fileSizeBytes > maxFileSizeBytes) {
      return DocumentMetadata(
        fileName: fileName,
        fileExtension: fileExtension,
        fileSizeBytes: fileSizeBytes,
        pageCount: 1,
        isSupported: false,
        errorMessage: 'Kích thước tài liệu vượt quá giới hạn cho phép (Tối đa 50MB).',
      );
    }

    List<int>? bytes;
    try {
      bytes = await pickedFile.readAsBytes();
    } catch (_) {
      if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }
    }

    if (bytes == null || bytes.isEmpty) {
      return DocumentMetadata(
        fileName: fileName,
        fileExtension: fileExtension,
        fileSizeBytes: fileSizeBytes,
        pageCount: 1,
        isSupported: true,
      );
    }

    final pageCount = extractPageCount(bytes, fileExtension);
    return DocumentMetadata(
      fileName: fileName,
      fileExtension: fileExtension,
      fileSizeBytes: fileSizeBytes,
      pageCount: pageCount,
      isSupported: true,
    );
  }

  /// Read metadata from dart:io File
  static Future<DocumentMetadata> readFromFile(File file) async {
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'tai_lieu.pdf';
    final fileExtension = _extractExtension(fileName);
    final fileSizeBytes = await file.length();

    if (!_isExtensionSupported(fileExtension)) {
      return DocumentMetadata(
        fileName: fileName,
        fileExtension: fileExtension,
        fileSizeBytes: fileSizeBytes,
        pageCount: 1,
        isSupported: false,
        errorMessage: 'Hệ thống chỉ hỗ trợ tài liệu định dạng PDF hoặc DOCX/DOC.',
      );
    }

    final bytes = await file.readAsBytes();
    final pageCount = extractPageCount(bytes, fileExtension);

    return DocumentMetadata(
      fileName: fileName,
      fileExtension: fileExtension,
      fileSizeBytes: fileSizeBytes,
      pageCount: pageCount,
      isSupported: true,
    );
  }

  /// Extract page count based on file type
  static int extractPageCount(List<int> bytes, String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (ext == 'pdf') {
      return _extractPdfPages(bytes);
    } else if (ext == 'docx') {
      return _extractDocxPages(bytes);
    } else if (ext == 'doc') {
      // Legacy binary .doc format estimation based on size or fallback
      final estimated = (bytes.length / (25 * 1024)).ceil();
      return estimated.clamp(1, 999);
    }
    return 1;
  }

  static int _extractPdfPages(List<int> bytes) {
    try {
      final latin1String = String.fromCharCodes(bytes);

      // 1. Search for /Count N in /Pages dict
      final countMatches = RegExp(r'/Type\s*/Pages[^>]*?/Count\s+(\d+)').allMatches(latin1String);
      int maxCount = 0;
      for (final m in countMatches) {
        final c = int.tryParse(m.group(1) ?? '0') ?? 0;
        if (c > maxCount) maxCount = c;
      }
      if (maxCount > 0) return maxCount;

      // 2. Count /Type /Page objects (distinct single page nodes)
      final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(latin1String).length;
      if (pageMatches > 0) return pageMatches;

      // 3. Fallback: search any /Count N
      final anyCountMatches = RegExp(r'/Count\s+(\d+)').allMatches(latin1String);
      for (final m in anyCountMatches) {
        final c = int.tryParse(m.group(1) ?? '0') ?? 0;
        if (c > maxCount) maxCount = c;
      }
      if (maxCount > 0) return maxCount;
    } catch (_) {
      // Fallback on error
    }
    return 1;
  }

  static int _extractDocxPages(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Check docProps/app.xml for <Pages>N</Pages>
      final appXmlFile = archive.findFile('docProps/app.xml');
      if (appXmlFile != null) {
        final xmlContent = String.fromCharCodes(appXmlFile.content as List<int>);
        final document = XmlDocument.parse(xmlContent);
        final pagesElements = document.findAllElements('Pages');
        if (pagesElements.isNotEmpty) {
          final count = int.tryParse(pagesElements.first.innerText.trim()) ?? 0;
          if (count > 0) return count;
        }
      }

      // 2. Check word/document.xml for explicit page breaks
      final docFile = archive.findFile('word/document.xml');
      if (docFile != null) {
        final xmlContent = String.fromCharCodes(docFile.content as List<int>);
        final pageBreaks = RegExp(r'<w:br\s+[^>]*?w:type="page"|<w:lastRenderedPageBreak\b').allMatches(xmlContent).length;
        if (pageBreaks > 0) {
          return pageBreaks + 1;
        }

        // 3. Estimate from words in text elements
        final words = RegExp(r'<w:t[^>]*>([^<]+)</w:t>').allMatches(xmlContent)
            .map((m) => m.group(1) ?? '')
            .join(' ')
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        if (words > 0) {
          return (words / 350).ceil().clamp(1, 9999);
        }
      }
    } catch (_) {
      // Fallback on error
    }
    return 1;
  }

  static String _extractExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < fileName.length - 1) {
      return '.${fileName.substring(dotIndex + 1).toLowerCase()}';
    }
    return '';
  }

  static bool _isExtensionSupported(String extension) {
    final cleanExt = extension.toLowerCase().replaceAll('.', '');
    return supportedExtensions.contains(cleanExt);
  }
}
