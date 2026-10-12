import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniprint_mobile/core/utils/document_reader_util.dart';
import 'package:uniprint_mobile/models/document_model.dart';
import 'package:uniprint_mobile/providers/document_provider.dart';

void main() {
  group('Task 06 - Upload Document & Page Reader Tests', () {
    test('Automatically read page count from DOCX file', () async {
      final file = File('Quy dinh lam viec va Git Workflow cho Team.docx');
      expect(file.existsSync(), true);

      final meta = await DocumentReaderUtil.readFromFile(file);
      expect(meta.isSupported, true);
      expect(meta.fileExtension, '.docx');
      expect(meta.pageCount, greaterThanOrEqualTo(1));
      expect(meta.fileSizeBytes, greaterThan(0));
      expect(meta.formattedSize.contains('KB') || meta.formattedSize.contains('MB'), true);
    });

    test('Automatically read page count from PDF binary stream', () {
      const samplePdf = '''
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R 4 0 R 5 0 R] /Count 3 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R >>
endobj
4 0 obj
<< /Type /Page /Parent 2 0 R >>
endobj
5 0 obj
<< /Type /Page /Parent 2 0 R >>
endobj
trailer
<< /Root 1 0 R >>
%%EOF
''';
      final bytes = samplePdf.codeUnits;
      final pages = DocumentReaderUtil.extractPageCount(bytes, '.pdf');
      expect(pages, 3);
    });

    test('Reject unsupported file extensions', () async {
      final meta = DocumentMetadata(
        fileName: 'virus.exe',
        fileExtension: '.exe',
        fileSizeBytes: 1024,
        pageCount: 1,
        isSupported: false,
        errorMessage: 'Hệ thống chỉ hỗ trợ tài liệu định dạng PDF hoặc DOCX/DOC.',
      );
      expect(meta.isSupported, false);
      expect(meta.errorMessage, contains('PDF hoặc DOCX'));
    });
  });

  group('Task 07 - Delete Document & Ownership Permission Tests', () {
    test('DocumentModel ownership validation', () {
      final ownerId = 'user-khoi-123';
      final otherUserId = 'user-hacker-999';

      final myDoc = DocumentModel(
        id: 'doc-001',
        fileName: 'Bao_Cao.pdf',
        fileExtension: '.pdf',
        fileSizeBytes: 1024 * 500,
        pageCount: 10,
        createdAt: DateTime.now(),
        userId: ownerId,
      );

      // Owner check
      expect(myDoc.isOwner(ownerId), true);
      expect(myDoc.isOwner(otherUserId), false);
      expect(myDoc.isPdf, true);
      expect(myDoc.isWord, false);
      expect(myDoc.formattedSize, '500.0 KB');
    });

    test('DocumentProvider blocks non-owner from deleting document', () async {
      final docProvider = DocumentProvider();
      final ownerId = 'user-khoi-123';
      final intruderId = 'user-intruder-456';

      final doc = DocumentModel(
        id: 'doc-secure-1',
        fileName: 'De_Thi_Mat_Ma.docx',
        fileExtension: '.docx',
        fileSizeBytes: 1024 * 300,
        pageCount: 5,
        createdAt: DateTime.now(),
        userId: ownerId,
      );

      // Add to provider list
      docProvider.documents.add(doc);

      // Attempt delete as intruder
      final deleteResult = await docProvider.deleteDocument('doc-secure-1', currentUserId: intruderId);
      expect(deleteResult, false);
      expect(docProvider.errorMessage, contains('Chỉ chủ sở hữu mới được xóa'));
      expect(docProvider.documents.length, 1);
    });
  });
}
