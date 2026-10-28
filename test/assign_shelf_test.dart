import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uniprint_mobile/models/print_order_model.dart';
import 'package:uniprint_mobile/models/shelf_model.dart';
import 'package:uniprint_mobile/providers/shelf_provider.dart';
import 'package:uniprint_mobile/views/staff/components/assign_shelf_dialog.dart';
import 'package:uniprint_mobile/views/staff/components/staff_order_card.dart';

class MockShelfProviderForAssign extends ShelfProvider {
  @override
  Future<void> fetchShelves() async {
    // Keep test data
  }
}

void main() {
  group('Task 14 - Assign Order to Shelf Tests', () {
    final samplePrintingOrder = PrintOrderModel(
      id: 'order-101',
      orderCode: 'ORD-20261026-101',
      studentName: 'Nguyễn Cao Quí',
      documentName: 'KienTrucHeThong.pdf',
      numberOfCopies: 1,
      isColor: true,
      isDoubleSided: true,
      totalPrice: 20000,
      status: OrderStatus.printing,
      paymentStatus: 1,
      createdAt: DateTime.now(),
    );

    final sampleReadyOrderWithShelf = PrintOrderModel(
      id: 'order-102',
      orderCode: 'ORD-20261026-102',
      studentName: 'Lê Văn C',
      documentName: 'BaoCaoTotNghiep.pdf',
      numberOfCopies: 2,
      isColor: false,
      isDoubleSided: true,
      totalPrice: 30000,
      status: OrderStatus.readyForPickup,
      shelfCode: 'A1',
      paymentStatus: 1,
      createdAt: DateTime.now(),
    );

    testWidgets('StaffOrderCard with onAssignShelf renders "In xong & Xếp kệ" button', (tester) async {
      PrintOrderModel? assignedOrder;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffOrderCard(
              order: samplePrintingOrder,
              queueIndex: 1,
              onStatusChange: (o, s, t, d) {},
              onAssignShelf: (order) {
                assignedOrder = order;
              },
            ),
          ),
        ),
      );

      expect(find.text('In xong & Xếp kệ'), findsOneWidget);

      await tester.tap(find.text('In xong & Xếp kệ'));
      await tester.pump();

      expect(assignedOrder?.id, 'order-101');
    });

    testWidgets('StaffOrderCard renders shelf badge when shelfCode is assigned', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaffOrderCard(
              order: sampleReadyOrderWithShelf,
              queueIndex: 1,
              onStatusChange: (o, s, t, d) {},
            ),
          ),
        ),
      );

      expect(find.text('Kệ lưu trữ: A1'), findsOneWidget);
      expect(find.text('Đã xếp kệ A1 • Chờ sinh viên quét QR nhận'), findsOneWidget);
    });

    testWidgets('AssignShelfDialog renders available shelves and radio selection', (tester) async {
      final mockShelfProvider = MockShelfProviderForAssign();
      mockShelfProvider.setShelvesForTesting([
        ShelfModel(
          id: 'shelf-a1',
          shelfCode: 'A1',
          location: 'Tầng 1 - Thư viện',
          maxCapacity: 20,
          currentCount: 5,
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ShelfProvider>.value(
            value: mockShelfProvider,
            child: Scaffold(
              body: AssignShelfDialog(
                order: samplePrintingOrder,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Xếp Kệ Đơn ORD-20261026-101'), findsOneWidget);
      expect(find.text('Kệ A1'), findsOneWidget);
      expect(find.text('Còn 15 chỗ'), findsOneWidget);
      expect(find.text('Xác nhận xếp kệ'), findsOneWidget);
    });
  });
}
