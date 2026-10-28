import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/payment_model.dart';

/// Task 18: Gọi API thanh toán (Cash khi nhận / chuyển khoản VietQR).
class PaymentService {
  static dynamic _data(dynamic response) =>
      (response is Map<String, dynamic> && response.containsKey('data'))
      ? response['data']
      : response;

  static Future<PaymentModel> getPayment(String orderId) async {
    final response = await ApiClient.get(ApiEndpoints.paymentByOrder(orderId));
    return PaymentModel.fromJson(_data(response));
  }

  /// Sinh viên chọn phương thức thanh toán cho đơn của mình.
  static Future<PaymentModel> selectMethod(
    String orderId,
    PaymentMethodType method,
  ) async {
    final response = await ApiClient.put(
      ApiEndpoints.selectPaymentMethod(orderId),
      body: {'method': method.value},
    );
    return PaymentModel.fromJson(_data(response));
  }

  /// Staff xác nhận đã thu tiền mặt hoặc đã nhận chuyển khoản (kèm mã giao dịch).
  static Future<PaymentModel> confirmPayment(
    String orderId,
    PaymentMethodType method, {
    String? transactionCode,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.confirmPayment(orderId),
      body: {
        'method': method.value,
        'transactionCode': transactionCode?.trim(),
      },
    );
    return PaymentModel.fromJson(_data(response));
  }

  static Future<List<PaymentModel>> getUnpaid({String? keyword}) async {
    final url = Uri.parse(ApiEndpoints.unpaidPayments).replace(
      queryParameters: (keyword?.trim().isNotEmpty ?? false)
          ? {'keyword': keyword!.trim()}
          : null,
    );
    final data = _data(await ApiClient.get(url.toString()));
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PaymentModel.fromJson)
          .toList();
    }
    return [];
  }
}
