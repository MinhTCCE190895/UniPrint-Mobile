import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/print_order_model.dart';

class OrderService {
  static Future<PriceCalculationResult> calculatePrice({
    required int pageCount,
    required int numberOfCopies,
    required bool isColor,
    required bool isDoubleSided,
    required bool hasBinding,
    required bool hasStaple,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.calculatePrice,
      body: {
        'pageCount': pageCount,
        'numberOfCopies': numberOfCopies,
        'isColor': isColor,
        'isDoubleSided': isDoubleSided,
        'hasBinding': hasBinding,
        'hasStaple': hasStaple,
      },
      withAuth: true,
    );

    final data =
        (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;
    return PriceCalculationResult.fromJson(data);
  }

  static Future<PrintOrderModel> createOrder({
    required String documentId,
    required int numberOfCopies,
    required bool isColor,
    required bool isDoubleSided,
    required bool hasBinding,
    required bool hasStaple,
    int paymentMethod = 0,
    String? notes,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.printOrders,
      body: {
        'documentId': documentId,
        'numberOfCopies': numberOfCopies,
        'isColor': isColor,
        'isDoubleSided': isDoubleSided,
        'hasBinding': hasBinding,
        'hasStaple': hasStaple,
        'paymentMethod': paymentMethod,
        'notes': notes,
      },
      withAuth: true,
    );

    final data =
        (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;
    return PrintOrderModel.fromJson(data);
  }

  static Future<List<PrintOrderModel>> getMyOrders() async {
    final response = await ApiClient.get(ApiEndpoints.myOrders, withAuth: true);
    final data =
        (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;

    if (data is List) {
      return data.map((e) => PrintOrderModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<PrintOrderModel>> getStaffQueue() async {
    final response = await ApiClient.get(
      ApiEndpoints.staffQueue,
      withAuth: true,
    );
    final data =
        (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;

    if (data is List) {
      return data.map((e) => PrintOrderModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<String> updateOrderStatus(String id, int newStatus) async {
    final response = await ApiClient.patch(
      ApiEndpoints.updateOrderStatus(id),
      body: {'newStatus': newStatus},
      withAuth: true,
    );
    if (response is Map<String, dynamic> &&
        response.containsKey('message') &&
        response['message'] != null) {
      return response['message'] as String;
    }
    return 'Cập nhật trạng thái thành công.';
  }

  static Future<PrintOrderModel> scanPickupQr(String qrToken) async {
    final token = qrToken.trim();
    if (token.isEmpty) throw ArgumentError('Vui lòng nhập mã QR.');
    final response = await ApiClient.post(
      Uri.parse(ApiEndpoints.scanPickupQr)
          .replace(queryParameters: {'qrToken': token})
          .toString(),
      withAuth: true,
    );
    final data =
        (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;
    final order = PrintOrderModel.fromJson(data);
    if (order.id.isEmpty || order.status != OrderStatus.completed) {
      throw ApiResponseException(
        'Máy chủ chưa xác nhận đơn đã hoàn thành. Vui lòng tải lại đơn trước khi thử tiếp.',
      );
    }
    return order;
  }

  static Future<String> assignShelf(String id, String shelfId) async {
    final response = await ApiClient.post(
      ApiEndpoints.assignShelf(id),
      body: {'shelfId': shelfId},
      withAuth: true,
    );
    if (response is Map<String, dynamic> &&
        response.containsKey('message') &&
        response['message'] != null) {
      return response['message'] as String;
    }
    return 'Đã gán đơn hàng vào kệ thành công.';
  }

  static Future<void> cancelOrder(String id) async {
    await ApiClient.post(ApiEndpoints.cancelOrder(id), withAuth: true);
  }
}
