import 'package:flutter_test/flutter_test.dart';
import 'package:uniprint_mobile/models/print_order_model.dart';

void main() {
  test('Pickup QR expires exactly at deadline and requires ready status', () {
    final deadline = DateTime.utc(2026, 10, 19, 7);
    PrintOrderModel order({int status = 5, String token = 'token'}) =>
        PrintOrderModel.fromJson({
          'status': status,
          'qrToken': token,
          'qrExpiresAt': deadline.toIso8601String(),
        });
    expect(
      order().canShowPickupQrAt(
        deadline.subtract(const Duration(microseconds: 1)),
      ),
      isTrue,
    );
    expect(order().canShowPickupQrAt(deadline), isFalse);
    expect(
      order().canShowPickupQrAt(deadline.add(const Duration(seconds: 1))),
      isFalse,
    );
    for (final status in [1, 2, 3, 4, 6, 7]) {
      expect(
        order(status: status)
            .canShowPickupQrAt(deadline.subtract(const Duration(days: 1))),
        isFalse,
      );
    }
    expect(
      order(token: '  ')
          .canShowPickupQrAt(deadline.subtract(const Duration(days: 1))),
      isFalse,
    );
  });
  test('Pickup expiry preserves server instant across time zones', () {
    final order = PrintOrderModel.fromJson({
      'qrToken': 'pickup-token',
      'qrExpiresAt': '2026-10-19T14:00:00+07:00',
      'status': 5,
    });
    expect(order.qrExpiresAt, DateTime.utc(2026, 10, 19, 7));
    expect(order.qrToken, 'pickup-token');
    expect(order.status, OrderStatus.readyForPickup);
  });

  test('Missing or malformed expiry does not invent a deadline', () {
    expect(PrintOrderModel.fromJson({}).qrExpiresAt, isNull);
    expect(
      PrintOrderModel.fromJson({'qrExpiresAt': 'invalid'}).qrExpiresAt,
      isNull,
    );
  });
}
