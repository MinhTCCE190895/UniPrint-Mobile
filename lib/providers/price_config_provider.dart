import 'package:flutter/foundation.dart';

import '../models/price_config_model.dart';
import '../services/price_config_service.dart';

/// Task 20: Trạng thái màn hình cấu hình bảng giá (Admin).
class PriceConfigProvider extends ChangeNotifier {
  PriceConfigModel? _current;
  List<PriceConfigModel> _history = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  PriceConfigModel? get current => _current;
  List<PriceConfigModel> get history => _history;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  @protected
  Future<PriceConfigModel> fetchActive() => PriceConfigService.getActive();

  @protected
  Future<List<PriceConfigModel>> fetchHistory() =>
      PriceConfigService.getHistory();

  @protected
  Future<({PriceConfigModel config, String message})> submitUpdate(
    PriceConfigModel config,
  ) => PriceConfigService.update(config);

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _current = await fetchActive();
      try {
        _history = await fetchHistory();
      } catch (_) {
        _history = [];
      }
    } catch (e) {
      _errorMessage = _clean(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Trả về thông báo thành công, hoặc null nếu lỗi (xem [errorMessage]).
  Future<String?> save(PriceConfigModel config) async {
    final errors = config.validate();
    if (errors.isNotEmpty) {
      _errorMessage = errors.join('\n');
      notifyListeners();
      return null;
    }
    if (_current != null && config.sameValuesAs(_current!)) {
      _errorMessage = 'Bảng giá không có thay đổi so với hiện tại.';
      notifyListeners();
      return null;
    }
    if (_isSaving) return null;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await submitUpdate(config);
      _current = result.config;
      try {
        _history = await fetchHistory();
      } catch (_) {}
      return result.message;
    } catch (e) {
      _errorMessage = _clean(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  static String _clean(Object e) => e
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('ApiResponseException: ', '');
}
