import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uniprint_mobile/models/document_model.dart';
import 'package:uniprint_mobile/models/user_model.dart';
import 'package:uniprint_mobile/providers/auth_provider.dart';
import 'package:uniprint_mobile/providers/document_provider.dart';
import 'package:uniprint_mobile/views/student/my_documents_screen.dart';

void main() {
  testWidgets('MyDocumentsScreen renders documents, search, and delete modal', (WidgetTester tester) async {
    final docProvider = DocumentProvider();
    final authProvider = AuthProvider();

    // Mock current user
    authProvider.setUserForTesting(
      UserModel(
        id: 'user-khoi-123',
        fullName: 'Trần Huỳnh Khôi',
        email: 'khoi@uniprint.edu.vn',
        role: 1,
      ),
    );

    // Mock sample documents
    final doc1 = DocumentModel(
      id: 'doc-pdf-1',
      fileName: 'Bao_Cao_PRN232.pdf',
      fileExtension: '.pdf',
      fileSizeBytes: 1024 * 650,
      pageCount: 15,
      createdAt: DateTime.now(),
      userId: 'user-khoi-123',
    );
    final doc2 = DocumentModel(
      id: 'doc-docx-2',
      fileName: 'Tai_Lieu_Huong_Dan.docx',
      fileExtension: '.docx',
      fileSizeBytes: 1024 * 320,
      pageCount: 8,
      createdAt: DateTime.now(),
      userId: 'user-khoi-123',
    );

    docProvider.documents.addAll([doc1, doc2]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<DocumentProvider>.value(value: docProvider),
        ],
        child: const MaterialApp(
          home: MyDocumentsScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify title and search bar exist
    expect(find.text('Kho Tài Liệu Cá Nhân'), findsOneWidget);
    expect(find.text('Bao_Cao_PRN232.pdf'), findsOneWidget);
    expect(find.text('Tai_Lieu_Huong_Dan.docx'), findsOneWidget);
    expect(find.text('15 trang'), findsOneWidget);
    expect(find.text('8 trang'), findsOneWidget);

    // Test search filter
    await tester.enterText(find.byType(TextField), 'Bao_Cao');
    await tester.pump();

    expect(find.text('Bao_Cao_PRN232.pdf'), findsOneWidget);
    expect(find.text('Tai_Lieu_Huong_Dan.docx'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Tai_Lieu_Huong_Dan.docx'), findsOneWidget);

    // Tap delete on first item
    final deleteButtons = find.byIcon(Icons.delete_outline);
    expect(deleteButtons, findsNWidgets(2));

    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    // Verify delete confirmation dialog appears
    expect(find.text('Xác nhận xóa tài liệu'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Xóa tài liệu'), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận xóa tài liệu'), findsNothing);
  });
}
