import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uniprint_mobile/models/user_model.dart';
import 'package:uniprint_mobile/providers/auth_provider.dart';
import 'package:uniprint_mobile/providers/user_management_provider.dart';
import 'package:uniprint_mobile/views/admin/user_management_screen.dart';

class FakeUserManagementProvider extends UserManagementProvider {
  final List<UserModel> mockUsers;

  FakeUserManagementProvider(this.mockUsers);

  @override
  Future<List<UserModel>> fetchUsersFromService({
    String? searchTerm,
    int? role,
    bool? isActive,
  }) async {
    var filtered = List<UserModel>.from(mockUsers);
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final term = searchTerm.toLowerCase();
      filtered = filtered
          .where((u) =>
              u.fullName.toLowerCase().contains(term) ||
              u.email.toLowerCase().contains(term) ||
              (u.phoneNumber != null && u.phoneNumber!.contains(term)))
          .toList();
    }
    if (role != null) {
      filtered = filtered.where((u) => u.role == role).toList();
    }
    if (isActive != null) {
      filtered = filtered.where((u) => u.isActive == isActive).toList();
    }
    return filtered;
  }

  @override
  Future<({UserModel user, String message})> submitRoleUpdate(
    String userId,
    int role,
  ) async {
    final idx = mockUsers.indexWhere((u) => u.id == userId);
    final updated = mockUsers[idx].copyWith(role: role);
    mockUsers[idx] = updated;
    return (user: updated, message: 'Cập nhật vai trò thành công.');
  }

  @override
  Future<({UserModel user, String message})> submitStatusToggle(
    String userId, {
    bool? isActive,
  }) async {
    final idx = mockUsers.indexWhere((u) => u.id == userId);
    final newActive = isActive ?? !mockUsers[idx].isActive;
    final updated = mockUsers[idx].copyWith(isActive: newActive);
    mockUsers[idx] = updated;
    return (
      user: updated,
      message: newActive ? 'Mở khóa thành công.' : 'Khóa thành công.',
    );
  }
}

void main() {
  group('Task 5 - UserModel Tests', () {
    test('UserModel serialization and role properties', () {
      final user = UserModel(
        id: 'u-1',
        fullName: 'Nguyen Van A',
        email: 'vana@uniprint.edu.vn',
        phoneNumber: '0901234567',
        role: 1,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(user.isStudent, isTrue);
      expect(user.isStaff, isFalse);
      expect(user.isAdmin, isFalse);
      expect(user.roleName, 'Sinh viên');

      final json = user.toJson();
      expect(json['id'], 'u-1');
      expect(json['isActive'], isTrue);

      final fromJson = UserModel.fromJson(json);
      expect(fromJson.fullName, 'Nguyen Van A');
      expect(fromJson.isActive, isTrue);
      expect(fromJson.role, 1);

      final updated = user.copyWith(role: 2, isActive: false);
      expect(updated.role, 2);
      expect(updated.isStaff, isTrue);
      expect(updated.roleName, 'Nhân viên');
      expect(updated.isActive, isFalse);
    });
  });

  group('Task 5 - UserManagementProvider Tests', () {
    test('Loads users and calculates statistics correctly', () async {
      final mockList = [
        UserModel(
          id: 'admin-1',
          fullName: 'Admin User',
          email: 'admin@uniprint.edu.vn',
          role: 3,
          isActive: true,
        ),
        UserModel(
          id: 'staff-1',
          fullName: 'Staff User',
          email: 'staff@uniprint.edu.vn',
          role: 2,
          isActive: true,
        ),
        UserModel(
          id: 'student-1',
          fullName: 'Student User',
          email: 'student@uniprint.edu.vn',
          role: 1,
          isActive: false, // Locked
        ),
      ];

      final provider = FakeUserManagementProvider(mockList);
      await provider.loadUsers();

      expect(provider.totalCount, 3);
      expect(provider.adminCount, 1);
      expect(provider.staffCount, 1);
      expect(provider.studentCount, 1);
      expect(provider.lockedCount, 1);
    });

    test('Filters users by role and status', () async {
      final mockList = [
        UserModel(
          id: 'u1',
          fullName: 'User 1',
          email: 'u1@test.com',
          role: 1,
          isActive: true,
        ),
        UserModel(
          id: 'u2',
          fullName: 'User 2',
          email: 'u2@test.com',
          role: 2,
          isActive: false,
        ),
      ];

      final provider = FakeUserManagementProvider(mockList);

      provider.setRoleFilter(1);
      await Future.delayed(Duration.zero);
      expect(provider.users.length, 1);
      expect(provider.users.first.id, 'u1');

      provider.setRoleFilter(null);
      provider.setStatusFilter(false);
      await Future.delayed(Duration.zero);
      expect(provider.users.length, 1);
      expect(provider.users.first.id, 'u2');
    });

    test('Updates user role and toggles user status', () async {
      final mockList = [
        UserModel(
          id: 'u1',
          fullName: 'Student To Staff',
          email: 'student@test.com',
          role: 1,
          isActive: true,
        ),
      ];

      final provider = FakeUserManagementProvider(mockList);
      await provider.loadUsers();

      final roleSuccess = await provider.updateUserRole('u1', 2);
      expect(roleSuccess, isTrue);
      expect(provider.users.first.role, 2);

      final statusSuccess = await provider.toggleUserStatus('u1', isActive: false);
      expect(statusSuccess, isTrue);
      expect(provider.users.first.isActive, isFalse);
    });
  });

  group('Task 5 - UserManagementScreen Widget Tests', () {
    testWidgets('Renders UserManagementScreen with user cards and actions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authProvider = AuthProvider();
      final adminUser = UserModel(
        id: 'admin-id',
        fullName: 'Admin Root',
        email: 'admin@uniprint.edu.vn',
        role: 3,
        isActive: true,
      );
      authProvider.setUserForTesting(adminUser);

      final mockList = [
        adminUser,
        UserModel(
          id: 'student-id',
          fullName: 'Le Van Sinh Vien',
          email: 'student@uniprint.edu.vn',
          phoneNumber: '0912345678',
          role: 1,
          isActive: true,
        ),
      ];
      final fakeProvider = FakeUserManagementProvider(mockList);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<UserManagementProvider>.value(
              value: fakeProvider,
            ),
          ],
          child: const MaterialApp(
            home: UserManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Stats
      expect(find.text('Quản Lý Người Dùng'), findsOneWidget);
      expect(find.text('Sinh viên'), findsWidgets);
      expect(find.text('Nhân viên'), findsWidgets);
      expect(find.text('Admin'), findsWidgets);

      // Verify Search & Filter
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Vai trò: '), findsOneWidget);
      expect(find.text('Trạng thái: '), findsOneWidget);

      // Verify User Cards
      expect(find.text('Admin Root'), findsOneWidget);
      expect(find.text('Bạn'), findsOneWidget);
      expect(find.text('Le Van Sinh Vien'), findsOneWidget);
      expect(find.text('student@uniprint.edu.vn'), findsOneWidget);
      expect(find.text('SĐT: 0912345678'), findsOneWidget);

      // Verify self action disabled indicator
      expect(find.text('Không thể tự đổi quyền / khóa'), findsOneWidget);

      // Verify action buttons for student
      expect(find.text('Phân quyền'), findsOneWidget);
      expect(find.text('Khóa'), findsOneWidget);

      // Tap 'Phân quyền' button to verify dialog opens
      await tester.tap(find.text('Phân quyền'));
      await tester.pumpAndSettle();

      expect(find.text('Phân quyền: Le Van Sinh Vien'), findsOneWidget);
      expect(find.text('Sinh viên (Student)'), findsOneWidget);
      expect(find.text('Nhân viên (Staff)'), findsOneWidget);
      expect(find.text('Quản trị viên (Admin)'), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Lưu thay đổi'), findsNothing);
    });
  });
}
