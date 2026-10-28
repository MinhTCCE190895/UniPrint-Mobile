import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/server_date.dart';

/// Task 18: Phương thức thanh toán — khớp enum PaymentMethod của backend.
enum PaymentMethodType {
  cash(1, 'Tiền mặt khi nhận', Icons.payments_outlined),
  vietQr(2, 'Chuyển khoản VietQR', Icons.qr_code_2);

  final int value;
  final String label;
  final IconData icon;
  const PaymentMethodType(this.value, this.label, this.icon);

  static PaymentMethodType fromValue(dynamic val) => PaymentMethodType.values
      .firstWhere((e) => e.value == val, orElse: () => PaymentMethodType.cash);
}

/// Task 18: Trạng thái hóa đơn — khớp enum PaymentStatus của backend.
enum PaymentStatusType {
  pending(1, 'Chưa thanh toán', AppColors.statusPending),
  paid(2, 'Đã thanh toán', AppColors.statusCompleted),
  failed(3, 'Thanh toán lỗi', AppColors.statusCancelled),
  refunded(4, 'Đã hoàn tiền', AppColors.textSecondary);

  final int value;
  final String label;
  final Color color;
  const PaymentStatusType(this.value, this.label, this.color);

  static PaymentStatusType fromValue(dynamic val) => PaymentStatusType.values
      .firstWhere((e) => e.value == val, orElse: () => PaymentStatusType.pending);
}

class VietQrInfo {
  final String bankBin;
  final String bankName;
  final String accountNo;
  final String accountName;
  final int amount;
  final String transferContent;
  final String qrPayload;
  final String qrImageUrl;

  VietQrInfo({
    required this.bankBin,
    required this.bankName,
    required this.accountNo,
    required this.accountName,
    required this.amount,
    required this.transferContent,
    required this.qrPayload,
    required this.qrImageUrl,
  });

  factory VietQrInfo.fromJson(Map<String, dynamic> json) => VietQrInfo(
    bankBin: json['bankBin']?.toString() ?? '',
    bankName: json['bankName']?.toString() ?? '',
    accountNo: json['accountNo']?.toString() ?? '',
    accountName: json['accountName']?.toString() ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    transferContent: json['transferContent']?.toString() ?? '',
    qrPayload: json['qrPayload']?.toString() ?? '',
    qrImageUrl: json['qrImageUrl']?.toString() ?? '',
  );
}

class PaymentModel {
  final String id;
  final String orderId;
  final String orderCode;
  final String studentName;
  final int orderStatus;
  final double amount;
  final PaymentMethodType method;
  final PaymentStatusType status;
  final String? transactionCode;
  final DateTime? paidAt;
  final VietQrInfo? vietQr;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.orderCode,
    required this.studentName,
    required this.orderStatus,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionCode,
    this.paidAt,
    this.vietQr,
  });

  bool get isPaid => status == PaymentStatusType.paid;

  /// Chỉ hiện QR khi chưa thanh toán, đã chọn VietQR và server trả payload hợp lệ.
  bool get canShowVietQr =>
      !isPaid &&
      method == PaymentMethodType.vietQr &&
      (vietQr?.qrPayload.isNotEmpty ?? false);

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: json['id']?.toString() ?? '',
    orderId: json['orderId']?.toString() ?? '',
    orderCode: json['orderCode']?.toString() ?? '',
    studentName: json['studentName']?.toString() ?? '',
    orderStatus: json['orderStatus'] is int ? json['orderStatus'] : 1,
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    method: PaymentMethodType.fromValue(json['method']),
    status: PaymentStatusType.fromValue(json['status']),
    transactionCode: json['transactionCode']?.toString(),
    paidAt: parseServerDate(json['paidAt']),
    vietQr: json['vietQr'] is Map<String, dynamic>
        ? VietQrInfo.fromJson(json['vietQr'])
        : null,
  );
}
