import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'payment_model.dart';

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
  final DateTime? qrExpiresAt;
  final int paymentStatus; // 1: Pending, 2: Paid, 3: Failed, 4: Refunded
  final int paymentMethod; // 1: Cash, 2: VietQR
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
    this.qrExpiresAt,
    required this.paymentStatus,
    this.paymentMethod = 1,
    required this.createdAt,
  });

  PaymentStatusType get paymentStatusType =>
      PaymentStatusType.fromValue(paymentStatus);
  PaymentMethodType get paymentMethodType =>
      PaymentMethodType.fromValue(paymentMethod);
  bool get isPaid => paymentStatusType == PaymentStatusType.paid;

  bool get canCancel =>
      (status == OrderStatus.pending || status == OrderStatus.processing) &&
      !isPaid; // Task 18: đơn đã thanh toán cần liên hệ quầy để hoàn tiền

  bool canShowPickupQrAt(DateTime now) =>
      status == OrderStatus.readyForPickup &&
      (qrToken?.trim().isNotEmpty ?? false) &&
      qrExpiresAt != null &&
      now.toUtc().isBefore(qrExpiresAt!);

  factory PrintOrderModel.fromJson(Map<String, dynamic> json) {
    return PrintOrderModel(
      id: json['id'] ?? '',
      orderCode: json['orderCode'] ?? '',
      studentName: json['studentName'] ?? '',
      documentName: json['documentName'] ?? '',
      numberOfCopies: json['numberOfCopies'] ?? 1,
      isColor: json['isColor'] ?? false,
      isDoubleSided: json['isDoubleSided'] ?? false,
      totalPrice: (json['totalPrice'] is num)
          ? (json['totalPrice'] as num).toDouble()
          : 0.0,
      status: OrderStatus.fromValue(json['status'] is int ? json['status'] : 1),
      shelfCode: json['shelfCode'],
      qrToken: json['qrToken'],
      qrExpiresAt: DateTime.tryParse(json['qrExpiresAt']?.toString() ?? '')
          ?.toUtc(),
      paymentStatus: json['paymentStatus'] is int ? json['paymentStatus'] : 1,
      paymentMethod: json['paymentMethod'] is int ? json['paymentMethod'] : 1,
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
      extraServicesTotal:
          (json['extraServicesTotal'] as num?)?.toDouble() ?? 0.0,
      totalEstimatedPrice:
          (json['totalEstimatedPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
