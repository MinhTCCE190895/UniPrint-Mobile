import 'package:flutter/foundation.dart';

import '../models/payment_model.dart';
import '../services/payment_service.dart';

/// Task 18: Quản lý hóa đơn thanh toán của đơn in.
/// Các hàm fetch/select/confirm được tách riêng để test có thể override.
class PaymentProvider extends ChangeNotifier {
  final Map<String, PaymentModel> _payments = {};
  final Set<String> _busyOrders = {};
  String? _errorMessage;

  PaymentModel? paymentOf(String orderId) => _payments[orderId];
  bool isBusy(String orderId) => _busyOrders.contains(orderId);
  String? get errorMessage => _errorMessage;

  @protected
  Future<PaymentModel> fetchPayment(String orderId) =>
      PaymentService.getPayment(orderId);

  @protected
  Future<PaymentModel> submitMethod(String orderId, PaymentMethodType method) =>
      PaymentService.selectMethod(orderId, method);

  @protected
  Future<PaymentModel> submitConfirm(
    String orderId,
    PaymentMethodType method,
    String? transactionCode,
  ) => PaymentService.confirmPayment(
    orderId,
    method,
    transactionCode: transactionCode,
  );

  Future<PaymentModel?> loadPayment(String orderId) =>
      _run(orderId, () => fetchPayment(orderId));

  Future<PaymentModel?> selectMethod(String orderId, PaymentMethodType method) =>
      _run(orderId, () => submitMethod(orderId, method));

  Future<PaymentModel?> confirmPayment(
    String orderId,
    PaymentMethodType method, {
    String? transactionCode,
  }) {
    if (method == PaymentMethodType.vietQr &&
        (transactionCode?.trim().isEmpty ?? true)) {
      _errorMessage = 'Vui lòng nhập mã giao dịch ngân hàng để đối soát.';
      notifyListeners();
      return Future.value(null);
    }
    return _run(
      orderId,
      () => submitConfirm(orderId, method, transactionCode?.trim()),
    );
  }

  Future<PaymentModel?> _run(
    String orderId,
    Future<PaymentModel> Function() action,
  ) async {
    if (_busyOrders.contains(orderId)) return null;
    _busyOrders.add(orderId);
    _errorMessage = null;
    notifyListeners();
    try {
      final payment = await action();
      _payments[orderId] = payment;
      return payment;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiResponseException: ', '');
      return null;
    } finally {
      _busyOrders.remove(orderId);
      notifyListeners();
    }
  }
}
