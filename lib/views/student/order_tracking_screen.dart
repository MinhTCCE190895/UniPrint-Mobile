import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order_tracking_model.dart';
import '../../models/print_order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/payment_provider.dart';
import 'components/payment_section.dart';

/// Task 19: Chi tiết theo dõi đơn — tiến trình, vị trí kệ nhận hàng, mã QR nhận và hóa đơn thanh toán.
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final String? orderCode;
  const OrderTrackingScreen({super.key, required this.orderId, this.orderCode});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with WidgetsBindingObserver {
  static final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  static final _dateFormat = DateFormat('HH:mm dd/MM/yyyy');

  OrderTrackingModel? _tracking;
  String? _error;
  bool _loading = false;
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    // Ẩn mã QR đúng lúc hết hạn khi màn hình vẫn đang mở.
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    // Làm mới cả hóa đơn khi đã hiển thị (nhân viên có thể vừa xác nhận thanh toán).
    if (_tracking != null) {
      context.read<PaymentProvider>().loadPayment(widget.orderId);
    }
    try {
      final tracking = await context.read<OrderProvider>().loadOrderTracking(
        widget.orderId,
      );
      if (mounted) setState(() => _tracking = tracking);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('ApiResponseException: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _tracking;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t?.orderCode ?? widget.orderCode ?? 'Chi tiết đơn in'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: t == null
            ? _buildPlaceholder()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(t),
                  const SizedBox(height: 12),
                  _buildTimeline(t),
                  const SizedBox(height: 12),
                  _buildShelf(t),
                  const SizedBox(height: 12),
                  _buildPickupQr(t),
                  const SizedBox(height: 12),
                  _buildDetails(t),
                  const SizedBox(height: 12),
                  PaymentSection(
                    orderId: t.id,
                    allowChangeMethod: t.status != OrderStatus.cancelled,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.statusCancelled),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _load,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(OrderTrackingModel t) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.orderCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.documentName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (t.createdAt != null)
                    Text(
                      'Đặt lúc ${_dateFormat.format(t.createdAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: t.status.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.status.color),
              ),
              child: Text(
                t.statusLabel,
                style: TextStyle(
                  color: t.status.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(OrderTrackingModel t) {
    return _card(
      title: 'Tiến trình đơn',
      child: Column(
        children: [
          for (var i = 0; i < t.timeline.length; i++)
            _timelineRow(t.timeline[i], isLast: i == t.timeline.length - 1),
        ],
      ),
    );
  }

  Widget _timelineRow(TimelineStep step, {required bool isLast}) {
    final cancelled = step.status == OrderStatus.cancelled;
    final color = cancelled
        ? AppColors.statusCancelled
        : step.isDone
        ? AppColors.statusCompleted
        : AppColors.textLight;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Icon(
                cancelled
                    ? Icons.cancel
                    : step.isDone
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: color,
                size: 22,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.isDone ? color : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 1),
              child: Text(
                step.label,
                style: TextStyle(
                  fontWeight: step.isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: step.isDone
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelf(OrderTrackingModel t) {
    return _card(
      title: 'Vị trí nhận tài liệu',
      child: t.shelfCode == null
          ? const Text(
              'Đơn chưa được xếp lên kệ.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Row(
              children: [
                const Icon(Icons.shelves, color: AppColors.secondary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kệ ${t.shelfCode}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      if (t.shelfLocation != null)
                        Text(
                          t.shelfLocation!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPickupQr(OrderTrackingModel t) {
    final qr = t.pickupQr;
    final now = DateTime.now();
    Widget content;
    if (qr != null && qr.canShowAt(now)) {
      content = Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                key: const Key('pickup-qr-image'),
                data: qr.qrToken!.trim(),
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 8),
            Text('Hạn nhận: ${_dateFormat.format(qr.expiresAt!)}'),
            const Text(
              'Đưa mã này cho nhân viên quầy in để nhận tài liệu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    } else if (qr?.isUsed == true || t.status == OrderStatus.completed) {
      content = Text(
        qr?.usedAt != null
            ? 'Đã nhận tài liệu lúc ${_dateFormat.format(qr!.usedAt!)}.'
            : 'Đã nhận tài liệu.',
        style: const TextStyle(
          color: AppColors.statusCompleted,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (t.status == OrderStatus.cancelled) {
      content = const Text(
        'Đơn đã hủy.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    } else if (qr != null &&
        (qr.isExpired || (qr.expiresAt != null && !now.isBefore(qr.expiresAt!)))) {
      content = const Text(
        'Mã QR đã hết hạn (EC04). Vui lòng liên hệ nhân viên.',
        style: TextStyle(color: AppColors.statusCancelled),
      );
    } else {
      content = const Text(
        'Mã QR sẽ hiển thị khi tài liệu đã in xong và sẵn sàng nhận.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return _card(title: 'Mã QR nhận tài liệu', child: content);
  }

  Widget _buildDetails(OrderTrackingModel t) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    return _card(
      title: 'Chi tiết đơn in',
      child: Column(
        children: [
          row('Tài liệu', '${t.documentName} (${t.pageCount} trang)'),
          row('Cấu hình', t.printConfigText),
          row('Đơn giá/trang', _currency.format(t.unitPricePerPage)),
          row('Tổng tiền', _currency.format(t.totalPrice), bold: true),
          if (t.notes?.trim().isNotEmpty ?? false) row('Ghi chú', t.notes!),
        ],
      ),
    );
  }
}
