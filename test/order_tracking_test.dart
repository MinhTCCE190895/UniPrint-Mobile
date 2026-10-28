import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uniprint_mobile/models/order_tracking_model.dart';
import 'package:uniprint_mobile/models/payment_model.dart';
import 'package:uniprint_mobile/models/print_order_model.dart';
import 'package:uniprint_mobile/providers/order_provider.dart';
import 'package:uniprint_mobile/providers/payment_provider.dart';
import 'package:uniprint_mobile/views/student/order_tracking_screen.dart';

Map<String, dynamic> trackingJson({
  int status = 5,
  bool canPickup = true,
  String? token = 'QR-track-token',
  DateTime? expiresAt,
  bool isUsed = false,
}) => {
  'id': 'order-1',
  'orderCode': 'ORD-20261028-TRACK1',
  'status': status,
  'statusLabel': 'Sẵn sàng nhận',
  'createdAt': '2026-10-28T01:00:00',
  'documentName': 'slide.pdf',
  'pageCount': 20,
  'numberOfCopies': 2,
  'isColor': true,
  'hasStaple': true,
  'unitPricePerPage': 1500,
  'totalPrice': 62000,
  'shelfCode': 'A1',
  'shelfLocation': 'Tầng 1 - Kệ Trái',
  'pickupQr': {
    'qrToken': token,
    'expiresAt': (expiresAt ?? DateTime.now().toUtc().add(const Duration(days: 3)))
        .toIso8601String(),
    'isUsed': isUsed,
    'isExpired': false,
    'canPickup': canPickup,
  },
  'payment': {'id': 'p1', 'orderId': 'order-1', 'amount': 62000, 'method': 1, 'status': 1},
  'timeline': [
    {'status': 1, 'label': 'Đã đặt đơn', 'isDone': true, 'isCurrent': false},
    {'status': 2, 'label': 'Đang chuẩn bị', 'isDone': true, 'isCurrent': false},
    {'status': 3, 'label': 'Đang in', 'isDone': true, 'isCurrent': false},
    {'status': 5, 'label': 'Sẵn sàng nhận tại kệ', 'isDone': true, 'isCurrent': true},
    {'status': 6, 'label': 'Đã nhận tài liệu', 'isDone': false, 'isCurrent': false},
  ],
};

class FakeTrackingOrders extends OrderProvider {
  FakeTrackingOrders(this.json);
  Map<String, dynamic> json;
  bool fail = false;

  @override
  Future<OrderTrackingModel> loadOrderTracking(String id) async {
    if (fail) throw Exception('Không tìm thấy đơn in.');
    return OrderTrackingModel.fromJson(json);
  }
}

class FakePayments extends PaymentProvider {
  @override
  Future<PaymentModel> fetchPayment(String orderId) async => PaymentModel.fromJson({
    'id': 'p1',
    'orderId': orderId,
    'amount': 62000,
    'method': 1,
    'status': 1,
  });
}

void main() {
  test('Tracking model parses shelf, QR, payment and timeline', () {
    final t = OrderTrackingModel.fromJson(trackingJson());
    expect(t.status, OrderStatus.readyForPickup);
    expect(t.shelfCode, 'A1');
    expect(t.printConfigText, '2 bản • In màu • 1 mặt • Bấm kim');
    expect(t.pickupQr!.canShowAt(DateTime.now()), isTrue);
    expect(t.payment!.method, PaymentMethodType.cash);
    expect(t.timeline.where((s) => s.isCurrent).single.status, OrderStatus.readyForPickup);
    expect(t.createdAt!.toUtc(), DateTime.utc(2026, 10, 28, 1));
  });

  test('QR is not shown when server denies pickup or deadline passed', () {
    expect(
      OrderTrackingModel.fromJson(trackingJson(canPickup: false)).pickupQr!.canShowAt(DateTime.now()),
      isFalse,
    );
    final deadline = DateTime.utc(2026, 10, 30);
    final qr = OrderTrackingModel.fromJson(trackingJson(expiresAt: deadline)).pickupQr!;
    expect(qr.canShowAt(deadline.subtract(const Duration(seconds: 1))), isTrue);
    expect(qr.canShowAt(deadline), isFalse);
  });

  Future<void> open(WidgetTester tester, FakeTrackingOrders orders) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OrderProvider>.value(value: orders),
          ChangeNotifierProvider<PaymentProvider>.value(value: FakePayments()),
        ],
        child: const MaterialApp(home: OrderTrackingScreen(orderId: 'order-1')),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Shows shelf, timeline and pickup QR for ready order', (tester) async {
    await open(tester, FakeTrackingOrders(trackingJson()));

    expect(find.text('ORD-20261028-TRACK1'), findsWidgets);
    expect(find.text('Kệ A1'), findsOneWidget);
    expect(find.text('Sẵn sàng nhận tại kệ'), findsOneWidget);
    expect(find.byKey(const Key('pickup-qr-image')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Completed order hides QR and says it was picked up', (tester) async {
    await open(
      tester,
      FakeTrackingOrders(trackingJson(status: 6, canPickup: false, token: null, isUsed: true)),
    );
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('Đã nhận tài liệu'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Error state allows retry', (tester) async {
    final orders = FakeTrackingOrders(trackingJson())..fail = true;
    await open(tester, orders);
    expect(find.textContaining('Không tìm thấy đơn in'), findsOneWidget);

    orders.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Kệ A1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
