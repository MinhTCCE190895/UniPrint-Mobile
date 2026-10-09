import 'package:flutter_test/flutter_test.dart';
import 'package:uniprint_mobile/models/user_model.dart';
import 'package:uniprint_mobile/models/print_order_model.dart';
import 'package:uniprint_mobile/main.dart';

void main() {
  group('UniPrint Unit & Widget Tests', () {
    test('UserModel fromJson deserializes properly', () {
      final json = {
        'userId': '11111111-1111-1111-1111-111111111111',
        'fullName': 'Nguyen Van A',
        'email': 'student@uniprint.edu.vn',
        'role': 1,
      };

      final user = UserModel.fromJson(json);
      expect(user.fullName, 'Nguyen Van A');
      expect(user.email, 'student@uniprint.edu.vn');
      expect(user.role, 1);
      expect(user.isStudent, true);
      expect(user.isStaff, false);
      expect(user.roleName, 'Sinh viên');
    });

    test('OrderStatus enum mapping correctly', () {
      expect(OrderStatus.fromValue(1), OrderStatus.pending);
      expect(OrderStatus.fromValue(3), OrderStatus.printing);
      expect(OrderStatus.fromValue(5), OrderStatus.readyForPickup);
      expect(OrderStatus.fromValue(6), OrderStatus.completed);
    });

    testWidgets('UniPrint App renders SplashScreen and finds title', (WidgetTester tester) async {
      await tester.pumpWidget(const UniPrintApp());
      expect(find.text('UniPrint'), findsOneWidget);
      expect(find.text('Hệ Thống In Ấn Thông Minh'), findsOneWidget);

      // Advance timer for delayed splash navigation
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
