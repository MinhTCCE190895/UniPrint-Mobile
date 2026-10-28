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
  group('Task 13 - Staff Shelves & Capacity Calculation Tests', () {
    test('ShelfModel accurately calculates isAvailable and occupancyRatio', () {
      final availableShelf = ShelfModel(
        id: 'shelf-1',
        shelfCode: 'A1',
        location: 'Tầng 1',
        maxCapacity: 20,
        currentCount: 5,
        createdAt: DateTime.now(),
      );

      expect(availableShelf.isAvailable, true);
      expect(availableShelf.occupancyRatio, 0.25);
      expect(availableShelf.availableSlots, 15);

      final fullShelf = ShelfModel(
        id: 'shelf-2',
        shelfCode: 'B1',
        location: 'Tầng 1',
        maxCapacity: 20,
        currentCount: 20,
        createdAt: DateTime.now(),
      );

      expect(fullShelf.isAvailable, false);
      expect(fullShelf.occupancyRatio, 1.0);
      expect(fullShelf.availableSlots, 0);
    });

    testWidgets('StaffShelvesScreen renders title, overview and floating action button', (tester) async {
      final mockProvider = MockShelfProvider();
      mockProvider.setShelvesForTesting([
        ShelfModel(
          id: 'shelf-1',
          shelfCode: 'A1',
          location: 'Tầng 1 - Thư viện',
          maxCapacity: 20,
          currentCount: 8,
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ShelfProvider>.value(
            value: mockProvider,
            child: const StaffShelvesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Quản Lý Kệ Lưu Trữ'), findsOneWidget);
      expect(find.text('Tổng quan sức chứa'), findsOneWidget);
      expect(find.text('Kệ A1'), findsOneWidget);
      expect(find.text('Thêm Kệ'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
