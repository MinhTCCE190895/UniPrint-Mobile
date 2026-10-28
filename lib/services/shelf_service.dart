import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/shelf_model.dart';

class ShelfService {
  static Future<List<ShelfModel>> getShelves() async {
    final response = await ApiClient.get(ApiEndpoints.shelves, withAuth: true);
    final data = (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;

    if (data is List) {
      return data.map((e) => ShelfModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<ShelfModel>> getAvailableShelves() async {
    final response = await ApiClient.get(ApiEndpoints.availableShelves, withAuth: true);
    final data = (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;

    if (data is List) {
      return data.map((e) => ShelfModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<ShelfModel> createShelf({
    required String shelfCode,
    String location = 'Main Library Floor 1',
    int maxCapacity = 20,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.shelves,
      body: {
        'shelfCode': shelfCode,
        'location': location,
        'maxCapacity': maxCapacity,
      },
      withAuth: true,
    );
    final data = (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;
    return ShelfModel.fromJson(data);
  }

  static Future<ShelfModel> updateShelf({
    required String id,
    required String shelfCode,
    required String location,
    required int maxCapacity,
  }) async {
    final response = await ApiClient.put(
      ApiEndpoints.shelfById(id),
      body: {
        'shelfCode': shelfCode,
        'location': location,
        'maxCapacity': maxCapacity,
      },
      withAuth: true,
    );
    final data = (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;
    return ShelfModel.fromJson(data);
  }

  static Future<void> deleteShelf(String id) async {
    await ApiClient.delete(ApiEndpoints.shelfById(id), withAuth: true);
  }
}
