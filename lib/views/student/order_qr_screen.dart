import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/print_order_model.dart';
import '../../providers/order_provider.dart';

class OrderQrScreen extends StatefulWidget {
  final PrintOrderModel order;
  const OrderQrScreen({super.key, required this.order});

  @override
  State<OrderQrScreen> createState() => _OrderQrScreenState();
}

class _OrderQrScreenState extends State<OrderQrScreen>
    with WidgetsBindingObserver {
  PrintOrderModel? _order;
  String? _error;
  Timer? _timer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _reload() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _order = null;
      _error = null;
    });
    try {
      final order = await context.read<OrderProvider>().loadPickupOrder(
        widget.order.id,
      );
      if (mounted) setState(() => _order = order);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không thể tải mã nhận tài liệu. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order ?? widget.order;
    final qrData = order.qrToken?.trim() ?? '';
    final expiry = order.qrExpiresAt;
    final expired = expiry != null && !DateTime.now().toUtc().isBefore(expiry);
    final canShow = _order != null && order.canShowPickupQrAt(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mã QR Nhận Tài Liệu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.orderCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.documentName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (order.shelfCode != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Kệ nhận: ${order.shelfCode}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: canShow
                          ? QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 200.0,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: _order == null && _error == null
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      _error ??
                                          (order.status == OrderStatus.completed
                                              ? 'Đơn đã được nhận.'
                                              : expired
                                              ? 'Mã QR đã hết hạn. Vui lòng liên hệ nhân viên.'
                                              : 'Mã QR nhận tài liệu chưa sẵn sàng.'),
                                    ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    if (canShow)
                      Text(
                        'Hạn nhận: ${DateFormat('dd/MM/yyyy HH:mm').format(expiry!.toLocal())}',
                      ),
                    TextButton(
                      onPressed: _loading ? null : _reload,
                      child: const Text('Tải lại'),
                    ),
                    const Text(
                      'Đưa mã QR này cho nhân viên quầy in để xác nhận và nhận tài liệu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
