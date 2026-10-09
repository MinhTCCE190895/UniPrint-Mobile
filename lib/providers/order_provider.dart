import 'package:flutter/material.dart';
import '../models/print_order_model.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  List<PrintOrderModel> _myOrders = [];
  List<PrintOrderModel> _staffQueue = [];
  PriceCalculationResult? _estimatedPrice;
  bool _isLoading = false;
  String? _errorMessage;

  List<PrintOrderModel> get myOrders => _myOrders;
  List<PrintOrderModel> get staffQueue => _staffQueue;
  PriceCalculationResult? get estimatedPrice => _estimatedPrice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  Future<bool> updateStatus(String orderId, int newStatus) async {
    try {
      await OrderService.updateOrderStatus(orderId, newStatus);
      await loadStaffQueue();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<PrintOrderModel?> verifyPickup(String qrToken) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await OrderService.scanPickupQr(qrToken);
      await loadStaffQueue();
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      await OrderService.cancelOrder(orderId);
      await loadMyOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
