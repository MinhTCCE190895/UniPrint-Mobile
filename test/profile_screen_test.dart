import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uniprint_mobile/models/user_model.dart';
import 'package:uniprint_mobile/providers/auth_provider.dart';
import 'package:uniprint_mobile/views/profile/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen renders user info and forms properly', (tester) async {
    final authProvider = AuthProvider();
    final testUser = UserModel(
      id: 'test-user-id',
      fullName: 'Tran Cong Minh',
      email: 'minhtc@uniprint.edu.vn',
      phoneNumber: '0901234567',
      role: 1, // Student
    );
    authProvider.setUserForTesting(testUser);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    // Verify user info is displayed
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
    expect(find.text('Tran Cong Minh'), findsNWidgets(2)); // in header card and in TextFormField
    expect(find.text('minhtc@uniprint.edu.vn'), findsOneWidget);
    expect(find.text('Sinh viên'), findsOneWidget);

    // Verify form sections exist
    expect(find.text('Cập nhật thông tin'), findsOneWidget);
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
    expect(find.text('Lưu thông tin'), findsOneWidget);
    expect(find.text('Cập nhật mật khẩu'), findsOneWidget);

    // Verify fields populated
    expect(find.widgetWithText(TextFormField, '0901234567'), findsOneWidget);
  });
}
