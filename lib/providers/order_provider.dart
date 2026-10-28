import 'package:flutter/material.dart';

import '../models/print_order_model.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  List<PrintOrderModel> _myOrders = [];
  List<PrintOrderModel> _staffQueue = [];
  PriceCalculationResult? _estimatedPrice;
  bool _isLoading = false;
  bool _isVerifyingPickup = false;
  String? _errorMessage;

  List<PrintOrderModel> get myOrders => _myOrders;
  List<PrintOrderModel> get staffQueue => _staffQueue;
  PriceCalculationResult? get estimatedPrice => _estimatedPrice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<PrintOrderModel> loadPickupOrder(String id) async {
    final orders = await OrderService.getMyOrders();
    final order = orders.firstWhere((order) => order.id == id);
    _myOrders = orders;
    notifyListeners();
    return order;
  }

  Future<void> loadMyOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myOrders = await OrderService.getMyOrders();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStaffQueue() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _staffQueue = await OrderService.getStaffQueue();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> calculatePriceRealtime({
    required int pageCount,
    required int numberOfCopies,
    required bool isColor,
    required bool isDoubleSided,
    required bool hasBinding,
    required bool hasStaple,
  }) async {
    try {
      _estimatedPrice = await OrderService.calculatePrice(
        pageCount: pageCount,
        numberOfCopies: numberOfCopies,
        isColor: isColor,
        isDoubleSided: isDoubleSided,
        hasBinding: hasBinding,
        hasStaple: hasStaple,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<PrintOrderModel?> createOrder({
    required String documentId,
    required int numberOfCopies,
    required bool isColor,
    required bool isDoubleSided,
    required bool hasBinding,
    required bool hasStaple,
    int paymentMethod = 0,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newOrder = await OrderService.createOrder(
        documentId: documentId,
        numberOfCopies: numberOfCopies,
        isColor: isColor,
        isDoubleSided: isDoubleSided,
        hasBinding: hasBinding,
        hasStaple: hasStaple,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      _myOrders.insert(0, newOrder);
      _isLoading = false;
      notifyListeners();
      return newOrder;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Đơn in đang chờ xử lý in (Pending, Processing, Printing) theo thứ tự FIFO
  List<PrintOrderModel> get queuePendingOrders => _staffQueue
      .where((order) =>
          order.status == OrderStatus.pending ||
          order.status == OrderStatus.processing ||
          order.status == OrderStatus.printing)
      .toList();

  /// Đơn in đã xong (ReadyForPickup, ShelfAssigned) chờ sinh viên nhận
  List<PrintOrderModel> get queueReadyOrders => _staffQueue
      .where((order) =>
          order.status == OrderStatus.readyForPickup ||
          order.status == OrderStatus.shelfAssigned)
      .toList();

  Future<({bool success, String message})> updateStatus(
    String orderId,
    int newStatus,
  ) async {
    try {
      final msg = await OrderService.updateOrderStatus(orderId, newStatus);
      await loadStaffQueue();
      return (success: true, message: msg);
    } catch (e) {
      final cleanMsg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiResponseException: ', '');
      _errorMessage = cleanMsg;
      notifyListeners();
      return (success: false, message: cleanMsg);
    }
  }

  Future<({bool success, String message})> assignShelf(
    String orderId,
    String shelfId,
  ) async {
    try {
      final msg = await OrderService.assignShelf(orderId, shelfId);
      await loadStaffQueue();
      return (success: true, message: msg);
    } catch (e) {
      final cleanMsg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiResponseException: ', '');
      _errorMessage = cleanMsg;
      notifyListeners();
      return (success: false, message: cleanMsg);
    }
  }

  Future<PrintOrderModel?> verifyPickup(String qrToken) async {
    if (_isVerifyingPickup) return null;
    _isVerifyingPickup = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await OrderService.scanPickupQr(qrToken);
      _staffQueue.removeWhere((order) => order.id == res.id);
      final index = _myOrders.indexWhere((order) => order.id == res.id);
      if (index >= 0) _myOrders[index] = res;
      try {
        _staffQueue = await OrderService.getStaffQueue();
      } catch (_) {
        _errorMessage =
            'Đã hoàn tất nhận tài liệu nhưng chưa tải lại được hàng đợi.';
      }
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isVerifyingPickup = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    final order = _myOrders.where((o) => o.id == orderId).firstOrNull;
    if (order != null && !order.canCancel) {
      _errorMessage = 'Đơn hàng đang in hoặc đã hoàn tất, không thể hủy.';
      notifyListeners();
      return false;
    }
    try {
      await OrderService.cancelOrder(orderId);
      await loadMyOrders();
      return true;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiResponseException: ', '');
      notifyListeners();
      return false;
    }
  }
}
