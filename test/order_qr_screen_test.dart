import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uniprint_mobile/models/print_order_model.dart';
import 'package:uniprint_mobile/providers/order_provider.dart';
import 'package:uniprint_mobile/views/student/order_qr_screen.dart';

class PickupOrders extends OrderProvider {
  PickupOrders(this.order);
  PrintOrderModel order;
  bool fail = false;

  @override
  Future<PrintOrderModel> loadPickupOrder(String id) async {
    if (fail) throw Exception('offline');
    return order;
  }
}

PrintOrderModel pickupOrder({
  int status = 5,
  String? token = 'pickup-token',
  DateTime? expiry,
}) => PrintOrderModel.fromJson({
  'id': 'order-1',
  'orderCode': 'UP001',
  'documentName': 'Document',
  'status': status,
  'qrToken': token,
  'qrExpiresAt': expiry?.toIso8601String(),
});

void main() {
  Future<void> open(WidgetTester tester, PickupOrders provider) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<OrderProvider>.value(
        value: provider,
        child: MaterialApp(home: OrderQrScreen(order: provider.order)),
      ),
    );
    await tester.pump();
  }

  testWidgets('Displays server token and removes it after completed refresh', (
    tester,
  ) async {
    final provider = PickupOrders(
      pickupOrder(expiry: DateTime.now().toUtc().add(const Duration(days: 7))),
    );
    await open(tester, provider);
    expect(find.byType(QrImageView), findsOneWidget);
    provider.order = pickupOrder(status: 6);
    await tester.tap(find.text('Tải lại'));
    await tester.pump();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Đơn đã được nhận.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Expired token is hidden', (tester) async {
    await open(
      tester,
      PickupOrders(
        pickupOrder(
          expiry: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
        ),
      ),
    );
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('Mã QR đã hết hạn'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Missing expiry never falls back to order ID', (tester) async {
    await open(tester, PickupOrders(pickupOrder()));
    expect(find.byType(QrImageView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Offline refresh hides cached QR and permits retry', (
    tester,
  ) async {
    final provider = PickupOrders(
      pickupOrder(expiry: DateTime.now().toUtc().add(const Duration(days: 7))),
    )..fail = true;
    await open(tester, provider);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('Không thể tải mã'), findsOneWidget);
    provider.fail = false;
    await tester.tap(find.text('Tải lại'));
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
