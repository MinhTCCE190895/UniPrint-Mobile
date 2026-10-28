import '../core/utils/server_date.dart';
import 'payment_model.dart';
import 'print_order_model.dart';

/// Task 19: Một bước trong tiến trình đơn in.
class TimelineStep {
  final OrderStatus status;
  final String label;
  final bool isDone;
  final bool isCurrent;

  TimelineStep({
    required this.status,
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  factory TimelineStep.fromJson(Map<String, dynamic> json) => TimelineStep(
    status: OrderStatus.fromValue(json['status'] is int ? json['status'] : 1),
    label: json['label']?.toString() ?? '',
    isDone: json['isDone'] == true,
    isCurrent: json['isCurrent'] == true,
  );
}

/// Task 19: Thông tin mã QR nhận tài liệu (token chỉ có khi được phép nhận).
class PickupQrInfo {
  final String? qrToken;
  final DateTime? expiresAt;
  final bool isUsed;
  final DateTime? usedAt;
  final bool isExpired;
  final bool canPickup;

  PickupQrInfo({
    this.qrToken,
    this.expiresAt,
    required this.isUsed,
    this.usedAt,
    required this.isExpired,
    required this.canPickup,
  });

  /// Kiểm tra lại cả phía client để ẩn QR đúng lúc hết hạn khi màn hình đang mở.
  bool canShowAt(DateTime now) =>
      canPickup &&
      (qrToken?.trim().isNotEmpty ?? false) &&
      expiresAt != null &&
      now.isBefore(expiresAt!);

  factory PickupQrInfo.fromJson(Map<String, dynamic> json) => PickupQrInfo(
    qrToken: json['qrToken']?.toString(),
    expiresAt: parseServerDate(json['expiresAt']),
    isUsed: json['isUsed'] == true,
    usedAt: parseServerDate(json['usedAt']),
    isExpired: json['isExpired'] == true,
    canPickup: json['canPickup'] == true,
  );
}

/// Task 19: Chi tiết theo dõi đơn in.
class OrderTrackingModel {
  final String id;
  final String orderCode;
  final OrderStatus status;
  final String statusLabel;
  final DateTime? createdAt;
  final String? notes;
  final bool canCancel;
  final String studentName;
  final String documentName;
  final int pageCount;
  final int numberOfCopies;
  final bool isColor;
  final bool isDoubleSided;
  final bool hasBinding;
  final bool hasStaple;
  final double unitPricePerPage;
  final double totalPrice;
  final String? shelfCode;
  final String? shelfLocation;
  final PickupQrInfo? pickupQr;
  final PaymentModel? payment;
  final List<TimelineStep> timeline;

  OrderTrackingModel({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.statusLabel,
    this.createdAt,
    this.notes,
    required this.canCancel,
    required this.studentName,
    required this.documentName,
    required this.pageCount,
    required this.numberOfCopies,
    required this.isColor,
    required this.isDoubleSided,
    required this.hasBinding,
    required this.hasStaple,
    required this.unitPricePerPage,
    required this.totalPrice,
    this.shelfCode,
    this.shelfLocation,
    this.pickupQr,
    this.payment,
    required this.timeline,
  });

  String get printConfigText {
    final parts = <String>[
      '$numberOfCopies bản',
      isColor ? 'In màu' : 'Đen trắng',
      isDoubleSided ? '2 mặt' : '1 mặt',
      if (hasBinding) 'Đóng gáy',
      if (hasStaple) 'Bấm kim',
    ];
    return parts.join(' • ');
  }

  factory OrderTrackingModel.fromJson(Map<String, dynamic> json) {
    final status = OrderStatus.fromValue(
      json['status'] is int ? json['status'] : 1,
    );
    return OrderTrackingModel(
      id: json['id']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '',
      status: status,
      statusLabel: json['statusLabel']?.toString() ?? status.label,
      createdAt: parseServerDate(json['createdAt']),
      notes: json['notes']?.toString(),
      canCancel: json['canCancel'] == true,
      studentName: json['studentName']?.toString() ?? '',
      documentName: json['documentName']?.toString() ?? '',
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
      numberOfCopies: (json['numberOfCopies'] as num?)?.toInt() ?? 1,
      isColor: json['isColor'] == true,
      isDoubleSided: json['isDoubleSided'] == true,
      hasBinding: json['hasBinding'] == true,
      hasStaple: json['hasStaple'] == true,
      unitPricePerPage: (json['unitPricePerPage'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      shelfCode: json['shelfCode']?.toString(),
      shelfLocation: json['shelfLocation']?.toString(),
      pickupQr: json['pickupQr'] is Map<String, dynamic>
          ? PickupQrInfo.fromJson(json['pickupQr'])
          : null,
      payment: json['payment'] is Map<String, dynamic>
          ? PaymentModel.fromJson(json['payment'])
          : null,
      timeline: (json['timeline'] is List)
          ? (json['timeline'] as List)
                .whereType<Map<String, dynamic>>()
                .map(TimelineStep.fromJson)
                .toList()
          : <TimelineStep>[],
    );
  }
}
