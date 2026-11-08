import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uniprint_mobile/models/shelf_model.dart';
import 'package:uniprint_mobile/providers/shelf_provider.dart';
import 'package:uniprint_mobile/views/staff/staff_shelves_screen.dart';

class MockShelfProvider extends ShelfProvider {
  @override
  Future<void> fetchShelves() async {
    // Keep test data intact
  }
}

void main() {
  group('Task 15 - Get Shelf Inventory Tests', () {
    test('ShelfInventoryResponse accurately parses JSON summary and items', () {
      final json = {
        'summary': {
          'totalShelves': 2,
          'totalCapacity': 40,
          'totalStoredOrders': 15,
          'availableShelvesCount': 1,
          'fullShelvesCount': 1,
          'overallOccupancyRate': 37.5,
        },
        'shelves': [
          {
            'id': 'shelf-1',
            'shelfCode': 'A1',
            'location': 'Tầng 1',
            'maxCapacity': 20,
            'currentCount': 15,
            'createdAt': DateTime.now().toIso8601String(),
            'storedOrders': [
              {
                'orderId': 'ord-1',
                'orderCode': 'ORD-A1-001',
                'studentName': 'Nguyen Van A',
                'documentName': 'BaoCao.pdf',
                'numberOfCopies': 2,
                'isColor': true,
                'isDoubleSided': false,
                'totalPrice': 20000,
                'status': 'ReadyForPickup',
                'isPaid': true,
                'createdAt': DateTime.now().toIso8601String(),
              }
            ],
          }
        ]
      };

      final response = ShelfInventoryResponse.fromJson(json);
      expect(response.summary.totalShelves, 2);
      expect(response.summary.totalCapacity, 40);
      expect(response.summary.totalStoredOrders, 15);
      expect(response.summary.overallOccupancyRate, 37.5);
      expect(response.shelves.length, 1);
      expect(response.shelves[0].shelfCode, 'A1');
      expect(response.shelves[0].storedOrders.length, 1);
      expect(response.shelves[0].storedOrders[0].orderCode, 'ORD-A1-001');
      expect(response.shelves[0].storedOrders[0].isPaid, true);
    });

    testWidgets(
        'StaffShelvesScreen displays inventory button and opens inventory sheet with orders',
        (tester) async {
      final mockProvider = MockShelfProvider();
      final orderItem = ShelfInventoryOrder(
        orderId: 'ord-101',
        orderCode: 'ORD-999',
        studentName: 'Tran Thi B',
        documentName: 'LuanVan.pdf',
        numberOfCopies: 1,
        isColor: false,
        isDoubleSided: true,
        totalPrice: 12000,
        status: 'ReadyForPickup',
        isPaid: true,
        createdAt: DateTime.now(),
      );

      final inventoryItem = ShelfInventoryItem(
        id: 'shelf-10',
        shelfCode: 'C1',
        location: 'Khu C',
        maxCapacity: 20,
        currentCount: 1,
        createdAt: DateTime.now(),
        storedOrders: [orderItem],
      );

      mockProvider.setShelvesForTesting([inventoryItem]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ShelfProvider>.value(
            value: mockProvider,
            child: const StaffShelvesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check shelf rendered with inventory button
      expect(find.text('Kệ C1'), findsOneWidget);
      expect(find.text('Kiểm kê đơn hàng (1)'), findsOneWidget);

      // Tap inventory button
      await tester.tap(find.text('Kiểm kê đơn hàng (1)'));
      await tester.pumpAndSettle();

      // Bottom sheet should open with order details
      expect(find.text('Kiểm Kê Đơn Lưu Trữ'), findsOneWidget);
      expect(find.text('ORD-999'), findsOneWidget);
      expect(find.text('Tran Thi B'), findsOneWidget);
      expect(find.text('LuanVan.pdf'), findsOneWidget);
      expect(find.text('Đã thanh toán'), findsOneWidget);
    });

    testWidgets(
        'StaffShelvesScreen opens inventory sheet showing empty state when shelf has no orders',
        (tester) async {
      final mockProvider = MockShelfProvider();
      final emptyShelf = ShelfInventoryItem(
        id: 'shelf-20',
        shelfCode: 'D1',
        location: 'Khu D',
        maxCapacity: 20,
        currentCount: 0,
        createdAt: DateTime.now(),
        storedOrders: [],
      );

      mockProvider.setShelvesForTesting([emptyShelf]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ShelfProvider>.value(
            value: mockProvider,
            child: const StaffShelvesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Kiểm kê đơn hàng (Trống)'), findsOneWidget);

      await tester.tap(find.text('Kiểm kê đơn hàng (Trống)'));
      await tester.pumpAndSettle();

      expect(find.text('Kệ hiện đang trống'), findsOneWidget);
      expect(find.text('Chưa có đơn hàng nào đang lưu trữ trên kệ này.'),
          findsOneWidget);
    });
  });
}
