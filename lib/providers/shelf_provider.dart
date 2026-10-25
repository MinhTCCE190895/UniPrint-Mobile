import 'package:flutter/foundation.dart';
import '../models/shelf_model.dart';
import '../services/shelf_service.dart';

class ShelfProvider extends ChangeNotifier {
  List<ShelfModel> _shelves = [];
  List<ShelfModel> _availableShelves = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ShelfModel> get shelves => _shelves;
  List<ShelfModel> get availableShelves => _availableShelves;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalShelves => _shelves.length;
  int get availableShelvesCount => _shelves.where((s) => s.isAvailable).length;
  int get fullShelvesCount => _shelves.where((s) => !s.isAvailable).length;
  int get totalStoredOrders =>
      _shelves.fold(0, (sum, s) => sum + s.currentCount);
  int get totalCapacity => _shelves.fold(0, (sum, s) => sum + s.maxCapacity);

  @visibleForTesting
  void setShelvesForTesting(List<ShelfModel> items) {
    _shelves = items;
    _availableShelves = items.where((s) => s.isAvailable).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchShelves() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _shelves = await ShelfService.getShelves();
      _availableShelves = _shelves.where((s) => s.isAvailable).toList();
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiResponseException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableShelves() async {
    try {
      _availableShelves = await ShelfService.getAvailableShelves();
      notifyListeners();
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiResponseException: ', '');
      notifyListeners();
    }
  }

  Future<({bool success, String message})> createShelf({
    required String shelfCode,
    String location = 'Main Library Floor 1',
    int maxCapacity = 20,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newShelf = await ShelfService.createShelf(
        shelfCode: shelfCode,
        location: location,
        maxCapacity: maxCapacity,
      );
      await fetchShelves();
      return (
        success: true,
        message: 'Tạo kệ ${newShelf.shelfCode} thành công.'
      );
    } catch (e) {
      final cleanMsg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiResponseException: ', '');
      _errorMessage = cleanMsg;
      return (success: false, message: cleanMsg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<({bool success, String message})> updateShelf({
    required String id,
    required String shelfCode,
    required String location,
    required int maxCapacity,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await ShelfService.updateShelf(
        id: id,
        shelfCode: shelfCode,
        location: location,
        maxCapacity: maxCapacity,
      );
      await fetchShelves();
      return (
        success: true,
        message: 'Cập nhật kệ ${updated.shelfCode} thành công.'
      );
    } catch (e) {
      final cleanMsg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiResponseException: ', '');
      _errorMessage = cleanMsg;
      return (success: false, message: cleanMsg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<({bool success, String message})> deleteShelf(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ShelfService.deleteShelf(id);
      await fetchShelves();
      return (success: true, message: 'Đã xóa kệ thành công.');
    } catch (e) {
      final cleanMsg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiResponseException: ', '');
      _errorMessage = cleanMsg;
      return (success: false, message: cleanMsg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
