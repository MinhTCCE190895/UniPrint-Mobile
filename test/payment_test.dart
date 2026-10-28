import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uniprint_mobile/core/utils/server_date.dart';
import 'package:uniprint_mobile/models/payment_model.dart';
import 'package:uniprint_mobile/models/print_order_model.dart';
import 'package:uniprint_mobile/providers/payment_provider.dart';
import 'package:uniprint_mobile/views/student/components/payment_section.dart';

Map<String, dynamic> paymentJson({int method = 1, int status = 1}) => {
  'id': 'pay-1',
  'orderId': 'order-1',
  'orderCode': 'ORD-20261028-ABC123',
  'amount': 27050,
  'method': method,
  'status': status,
  'vietQr': method == 2 && status != 2
      ? {
          'bankName': 'Vietcombank',
          'accountNo': '1234567890',
          'accountName': 'UNIPRINT FPTU',
          'amount': 27050,
          'transferContent': 'ORD20261028ABC123',
          'qrPayload': '00020101021238570010A000000727',
        }
      : null,
};

class FakePaymentProvider extends PaymentProvider {
  FakePaymentProvider(this.current);
  PaymentModel current;
  final List<PaymentMethodType> selected = [];
  int confirmCalls = 0;

  @override
  Future<PaymentModel> fetchPayment(String orderId) async => current;

  @override
  Future<PaymentModel> submitMethod(String orderId, PaymentMethodType method) async {
    selected.add(method);
    current = PaymentModel.fromJson(paymentJson(method: method.value));
    return current;
  }

  @override
  Future<PaymentModel> submitConfirm(
    String orderId,
    PaymentMethodType method,
    String? transactionCode,
  ) async {
    confirmCalls++;
    current = PaymentModel.fromJson(paymentJson(method: method.value, status: 2));
    return current;
  }
}

void main() {
  group('Task 18 models', () {
    test('Payment status/method values match backend enums', () {
      final order = PrintOrderModel.fromJson({});
      expect(order.paymentStatusType, PaymentStatusType.pending);
      expect(order.paymentMethodType, PaymentMethodType.cash);
      expect(order.isPaid, isFalse);
      expect(
        PrintOrderModel.fromJson({'paymentStatus': 2, 'paymentMethod': 2}).isPaid,
        isTrue,
      );
    });

    test('VietQR is only shown for unpaid VietQR invoices with payload', () {
      expect(PaymentModel.fromJson(paymentJson(method: 2)).canShowVietQr, isTrue);
      expect(PaymentModel.fromJson(paymentJson(method: 1)).canShowVietQr, isFalse);
      expect(
        PaymentModel.fromJson(paymentJson(method: 2, status: 2)).canShowVietQr,
        isFalse,
      );
    });

    test('Server dates without zone are treated as UTC', () {
      expect(
        parseServerDate('2026-10-28T00:00:00')!.toUtc(),
        DateTime.utc(2026, 10, 28),
      );
      expect(
        parseServerDate('2026-10-28T07:00:00+07:00')!.toUtc(),
        DateTime.utc(2026, 10, 28),
      );
      expect(parseServerDate(null), isNull);
      expect(parseServerDate('bad'), isNull);
    });
  });

  group('Task 18 provider', () {
    test('VietQR confirmation requires a transaction code', () async {
      final provider = FakePaymentProvider(PaymentModel.fromJson(paymentJson()));
      final result = await provider.confirmPayment(
        'order-1',
        PaymentMethodType.vietQr,
        transactionCode: '  ',
      );
      expect(result, isNull);
      expect(provider.confirmCalls, 0);
      expect(provider.errorMessage, contains('mã giao dịch'));

      final ok = await provider.confirmPayment('order-1', PaymentMethodType.cash);
      expect(ok?.isPaid, isTrue);
      expect(provider.paymentOf('order-1')?.isPaid, isTrue);
    });
  });

  group('Task 18 PaymentSection', () {
    Future<void> open(WidgetTester tester, FakePaymentProvider provider) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: PaymentSection(orderId: 'order-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('Cash invoice hides QR, switching to VietQR shows it', (tester) async {
      final provider = FakePaymentProvider(PaymentModel.fromJson(paymentJson()));
      await open(tester, provider);

      expect(find.text('Chưa thanh toán'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);

      await tester.tap(find.text('Chuyển khoản VietQR'));
      await tester.pump();
      await tester.pump();

      expect(provider.selected, [PaymentMethodType.vietQr]);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('ORD20261028ABC123'), findsOneWidget);
    });

    testWidgets('Paid invoice hides method selector and QR', (tester) async {
      final provider = FakePaymentProvider(
        PaymentModel.fromJson(paymentJson(method: 2, status: 2)),
      );
      await open(tester, provider);

      expect(find.text('Đã thanh toán'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
    });
  });
}
