import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uniprint_mobile/models/order_tracking_model.dart';
import 'package:uniprint_mobile/models/payment_model.dart';
import 'package:uniprint_mobile/models/print_order_model.dart';
import 'package:uniprint_mobile/providers/auth_provider.dart';
import 'package:uniprint_mobile/providers/order_provider.dart';
import 'package:uniprint_mobile/providers/payment_provider.dart';
import 'package:uniprint_mobile/views/student/components/cancel_order_dialog.dart';
import 'package:uniprint_mobile/views/student/order_tracking_screen.dart';
import 'package:uniprint_mobile/views/student/student_home_screen.dart';

class FakeOrderProvider extends OrderProvider {
  final List<PrintOrderModel> mockOrders;
  OrderTrackingModel? mockTracking;
  bool cancelCalled = false;
  String? cancelledOrderId;

  FakeOrderProvider({required this.mockOrders, this.mockTracking});

  @override
  List<PrintOrderModel> get myOrders => mockOrders;

  @override
  bool get isLoading => false;

  @override
  Future<void> loadMyOrders() async {}

  @override
  Future<OrderTrackingModel> loadOrderTracking(String id) async {
    return mockTracking ??
        OrderTrackingModel(
          id: id,
          orderCode: 'ORD-TEST-001',
          status: OrderStatus.pending,
          statusLabel: 'Chờ xử lý',
          canCancel: true,
          studentName: 'Nguyen Van A',
          documentName: 'BaiTapLon.pdf',
          pageCount: 10,
          numberOfCopies: 1,
          isColor: false,
          isDoubleSided: true,
          hasBinding: false,
          hasStaple: false,
          unitPricePerPage: 500,
          totalPrice: 5000,
          timeline: [],
        );
  }

  @override
  Future<bool> cancelOrder(String orderId) async {
    cancelCalled = true;
    cancelledOrderId = orderId;
    return true;
  }
}

class FakeAuthProvider extends AuthProvider {
  @override
  bool get isAuthenticated => true;
}

class FakePaymentProvider extends PaymentProvider {
  @override
  Future<PaymentModel> fetchPayment(String orderId) async {
    return PaymentModel.fromJson({
      'id': 'pay-1',
      'orderId': orderId,
      'orderCode': 'ORD-TEST',
      'studentName': 'Student A',
      'orderStatus': 1,
      'amount': 5000,
      'method': 1,
      'status': 1,
    });
  }
}

void main() {
  group('Task 10 - Cancel Print Order Model & BR02 Rules', () {
    test('canCancel returns true for pending and processing unpaid orders', () {
      final pendingOrder = PrintOrderModel(
        id: '1',
        orderCode: 'ORD-001',
        studentName: 'Student A',
        documentName: 'doc.pdf',
        numberOfCopies: 1,
        isColor: false,
        isDoubleSided: true,
        totalPrice: 10000,
        status: OrderStatus.pending,
        paymentStatus: 1, // Pending
        createdAt: DateTime.now(),
      );
      expect(pendingOrder.canCancel, isTrue);

      final processingOrder = PrintOrderModel(
        id: '2',
        orderCode: 'ORD-002',
        studentName: 'Student A',
        documentName: 'doc.pdf',
        numberOfCopies: 1,
        isColor: false,
        isDoubleSided: true,
        totalPrice: 10000,
        status: OrderStatus.processing,
        paymentStatus: 1,
        createdAt: DateTime.now(),
      );
      expect(processingOrder.canCancel, isTrue);
    });

    test('BR02: canCancel returns false when status is printing or higher', () {
      final printingOrder = PrintOrderModel(
        id: '3',
        orderCode: 'ORD-003',
        studentName: 'Student A',
        documentName: 'doc.pdf',
        numberOfCopies: 1,
        isColor: false,
        isDoubleSided: true,
        totalPrice: 10000,
        status: OrderStatus.printing,
        paymentStatus: 1,
        createdAt: DateTime.now(),
      );
      expect(printingOrder.canCancel, isFalse);

      final completedOrder = PrintOrderModel(
        id: '4',
        orderCode: 'ORD-004',
        studentName: 'Student A',
        documentName: 'doc.pdf',
        numberOfCopies: 1,
        isColor: false,
        isDoubleSided: true,
        totalPrice: 10000,
        status: OrderStatus.completed,
        paymentStatus: 1,
        createdAt: DateTime.now(),
      );
      expect(completedOrder.canCancel, isFalse);
    });

    test('canCancel returns false when order is already paid', () {
      final paidPendingOrder = PrintOrderModel(
        id: '5',
        orderCode: 'ORD-005',
        studentName: 'Student A',
        documentName: 'doc.pdf',
        numberOfCopies: 1,
        isColor: false,
        isDoubleSided: true,
        totalPrice: 10000,
        status: OrderStatus.pending,
        paymentStatus: 2, // Paid
        createdAt: DateTime.now(),
      );
      expect(paidPendingOrder.canCancel, isFalse);
    });
  });

  group('Task 10 - CancelOrderDialog Widget Tests', () {
    testWidgets('CancelOrderDialog renders information and handles actions', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await CancelOrderDialog.show(
                    context,
                    orderCode: 'ORD-20261109-001',
                    documentName: 'BaoCaoDoAn.pdf',
                    totalPrice: 25000,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check content
      expect(find.text('Xác Nhận Hủy Đơn'), findsOneWidget);
      expect(find.text('ORD-20261109-001'), findsOneWidget);
      expect(find.text('BaoCaoDoAn.pdf'), findsOneWidget);
      expect(find.textContaining('Lưu ý: Chỉ cho phép hủy khi nhân viên chưa bắt đầu in'), findsOneWidget);
      expect(find.text('Không, giữ lại'), findsOneWidget);
      expect(find.text('Xác Nhận Hủy'), findsOneWidget);

      // Tap cancel button (Keep order)
      await tester.tap(find.text('Không, giữ lại'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(CancelOrderDialog), findsNothing);

      // Reopen and confirm cancel
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác Nhận Hủy'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(CancelOrderDialog), findsNothing);
    });
  });

  group('Task 10 - StudentHomeScreen Cancel Integration', () {
    testWidgets('Shows cancel button for pending order and blocking badge for printing order', (tester) async {
      final fakeOrders = [
        PrintOrderModel(
          id: 'ord-pending',
          orderCode: 'ORD-PENDING-01',
          studentName: 'Student A',
          documentName: 'tailieu_cho_in.pdf',
          numberOfCopies: 1,
          isColor: false,
          isDoubleSided: false,
          totalPrice: 15000,
          status: OrderStatus.pending,
          paymentStatus: 1,
          createdAt: DateTime.now(),
        ),
        PrintOrderModel(
          id: 'ord-printing',
          orderCode: 'ORD-PRINTING-02',
          studentName: 'Student A',
          documentName: 'tailieu_dang_in.pdf',
          numberOfCopies: 2,
          isColor: true,
          isDoubleSided: true,
          totalPrice: 30000,
          status: OrderStatus.printing,
          paymentStatus: 1,
          createdAt: DateTime.now(),
        ),
      ];

      final orderProvider = FakeOrderProvider(mockOrders: fakeOrders);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
            ChangeNotifierProvider<PaymentProvider>.value(value: FakePaymentProvider()),
          ],
          child: const MaterialApp(home: StudentHomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Check order codes
      expect(find.text('ORD-PENDING-01'), findsOneWidget);
      expect(find.text('ORD-PRINTING-02'), findsOneWidget);

      // For pending: shows "Hủy" button
      expect(find.text('Hủy'), findsOneWidget);

      // For printing: shows "Đang in, không thể hủy"
      expect(find.text('Đang in, không thể hủy'), findsOneWidget);

      // Tap Hủy opens CancelOrderDialog
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.byType(CancelOrderDialog), findsOneWidget);
      expect(find.text('ORD-PENDING-01'), findsNWidgets(2)); // in card and in dialog

      // Confirm cancel
      await tester.tap(find.text('Xác Nhận Hủy'));
      await tester.pumpAndSettle();

      expect(orderProvider.cancelCalled, isTrue);
      expect(orderProvider.cancelledOrderId, 'ord-pending');
    });
  });

  group('Task 10 - OrderTrackingScreen Cancel Integration', () {
    testWidgets('Shows cancel button and opens dialog when canCancel is true', (tester) async {
      final tracking = OrderTrackingModel(
        id: 'ord-track-1',
        orderCode: 'ORD-TRACK-01',
        status: OrderStatus.pending,
        statusLabel: 'Chờ xử lý',
        canCancel: true,
        studentName: 'Student A',
        documentName: 'slide_thuyet_trinh.pdf',
        pageCount: 15,
        numberOfCopies: 1,
        isColor: false,
        isDoubleSided: true,
        hasBinding: false,
        hasStaple: false,
        unitPricePerPage: 500,
        totalPrice: 7500,
        timeline: [],
      );

      final orderProvider = FakeOrderProvider(mockOrders: [], mockTracking: tracking);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<PaymentProvider>.value(value: FakePaymentProvider()),
          ],
          child: const MaterialApp(
            home: OrderTrackingScreen(orderId: 'ord-track-1', orderCode: 'ORD-TRACK-01'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check AppBar action button
      expect(find.text('Hủy đơn'), findsOneWidget);

      // Scroll to bottom button
      await tester.scrollUntilVisible(find.text('Hủy đơn in này'), 200);
      expect(find.text('Hủy đơn in này'), findsOneWidget);

      // Tap cancel in body
      await tester.tap(find.text('Hủy đơn in này'));
      await tester.pumpAndSettle();

      expect(find.byType(CancelOrderDialog), findsOneWidget);
      expect(find.text('slide_thuyet_trinh.pdf'), findsWidgets);

      // Confirm cancel
      await tester.tap(find.text('Xác Nhận Hủy'));
      await tester.pumpAndSettle();

      expect(orderProvider.cancelCalled, isTrue);
      expect(orderProvider.cancelledOrderId, 'ord-track-1');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Shows blocking notice when status is printing', (tester) async {
      final tracking = OrderTrackingModel(
        id: 'ord-track-2',
        orderCode: 'ORD-TRACK-02',
        status: OrderStatus.printing,
        statusLabel: 'Đang in',
        canCancel: false,
        studentName: 'Student A',
        documentName: 'slide_dang_in.pdf',
        pageCount: 15,
        numberOfCopies: 1,
        isColor: false,
        isDoubleSided: true,
        hasBinding: false,
        hasStaple: false,
        unitPricePerPage: 500,
        totalPrice: 7500,
        timeline: [],
      );

      final orderProvider = FakeOrderProvider(mockOrders: [], mockTracking: tracking);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<PaymentProvider>.value(value: FakePaymentProvider()),
          ],
          child: const MaterialApp(
            home: OrderTrackingScreen(orderId: 'ord-track-2', orderCode: 'ORD-TRACK-02'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hủy đơn'), findsNothing);
      expect(find.text('Hủy đơn in này'), findsNothing);
      await tester.scrollUntilVisible(find.textContaining('không thể hủy theo quy định (BR02)'), 200);
      expect(find.textContaining('Đơn hàng đang trong tiến trình in ấn, không thể hủy theo quy định (BR02)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

