import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum OrderStatus {
  pending(1, 'Chờ xử lý', AppColors.statusPending),
  processing(2, 'Đang chuẩn bị', AppColors.statusProcessing),
  printing(3, 'Đang in', AppColors.statusPrinting),
  shelfAssigned(4, 'Đã vào kệ', AppColors.statusShelf),
  readyForPickup(5, 'Sẵn sàng lấy', AppColors.statusReady),
  completed(6, 'Hoàn thành', AppColors.statusCompleted),
  cancelled(7, 'Đã hủy', AppColors.statusCancelled);

  final int value;
  final String label;
  final Color color;
  const OrderStatus(this.value, this.label, this.color);

  static OrderStatus fromValue(int val) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => OrderStatus.pending,
    );
  }
}

class PrintOrderModel {
  final String id;
  final String orderCode;
  final String studentName;
  final String documentName;
  final int numberOfCopies;
  final bool isColor;
  final bool isDoubleSided;
  final double totalPrice;
  final OrderStatus status;
  final String? shelfCode;
  final String? qrToken;
  final int paymentStatus; // 0: Pending, 1: Paid, 2: Failed
  final DateTime createdAt;

  PrintOrderModel({
    required this.id,
    required this.orderCode,
    required this.studentName,
    required this.documentName,
    required this.numberOfCopies,
    required this.isColor,
    required this.isDoubleSided,
    required this.totalPrice,
    required this.status,
    this.shelfCode,
    this.qrToken,
    required this.paymentStatus,
    required this.createdAt,
  });

  bool get canCancel => status == OrderStatus.pending || status == OrderStatus.processing;

  factory PrintOrderModel.fromJson(Map<String, dynamic> json) {
    return PrintOrderModel(
      id: json['id'] ?? '',
      orderCode: json['orderCode'] ?? '',
      studentName: json['studentName'] ?? '',
      documentName: json['documentName'] ?? '',
      numberOfCopies: json['numberOfCopies'] ?? 1,
      isColor: json['isColor'] ?? false,
      isDoubleSided: json['isDoubleSided'] ?? false,
      totalPrice: (json['totalPrice'] is num) ? (json['totalPrice'] as num).toDouble() : 0.0,
      status: OrderStatus.fromValue(json['status'] is int ? json['status'] : 1),
      shelfCode: json['shelfCode'],
      qrToken: json['qrToken'],
      paymentStatus: json['paymentStatus'] is int ? json['paymentStatus'] : 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class PriceCalculationResult {
  final double unitPricePerPage;
  final double pageSubtotal;
  final double extraServicesTotal;
  final double totalEstimatedPrice;

  PriceCalculationResult({
    required this.unitPricePerPage,
    required this.pageSubtotal,
    required this.extraServicesTotal,
    required this.totalEstimatedPrice,
  });

  factory PriceCalculationResult.fromJson(Map<String, dynamic> json) {
    return PriceCalculationResult(
      unitPricePerPage: (json['unitPricePerPage'] as num?)?.toDouble() ?? 0.0,
      pageSubtotal: (json['pageSubtotal'] as num?)?.toDouble() ?? 0.0,
      extraServicesTotal: (json['extraServicesTotal'] as num?)?.toDouble() ?? 0.0,
      totalEstimatedPrice: (json['totalEstimatedPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
