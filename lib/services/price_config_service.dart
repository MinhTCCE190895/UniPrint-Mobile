import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/price_config_model.dart';

/// Task 20: Gọi API bảng giá (xem / Admin cập nhật / lịch sử).
class PriceConfigService {
  static dynamic _data(dynamic response) =>
      (response is Map<String, dynamic> && response.containsKey('data'))
      ? response['data']
      : response;

  static Future<PriceConfigModel> getActive() async {
    final response = await ApiClient.get(ApiEndpoints.priceConfig, withAuth: false);
    return PriceConfigModel.fromJson(_data(response));
  }

  static Future<({PriceConfigModel config, String message})> update(
    PriceConfigModel config,
  ) async {
    final response = await ApiClient.put(
      ApiEndpoints.priceConfig,
      body: config.toUpdateJson(),
    );
    final message =
        (response is Map<String, dynamic> && response['message'] != null)
        ? response['message'].toString()
        : 'Đã cập nhật bảng giá.';
    return (config: PriceConfigModel.fromJson(_data(response)), message: message);
  }

  static Future<List<PriceConfigModel>> getHistory({int take = 10}) async {
    final data = _data(
      await ApiClient.get('${ApiEndpoints.priceConfigHistory}?take=$take'),
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PriceConfigModel.fromJson)
          .toList();
    }
    return [];
  }
}
