import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/payment_model.dart';
import '../../../models/print_order_model.dart';
import '../../../providers/payment_provider.dart';

/// Task 18: Staff xác nhận đã thu tiền mặt hoặc đã nhận chuyển khoản VietQR.
/// Trả về hóa đơn đã thanh toán, hoặc null nếu đóng/không thành công.
class ConfirmPaymentDialog extends StatefulWidget {
  final PrintOrderModel order;
  const ConfirmPaymentDialog({super.key, required this.order});

  static Future<PaymentModel?> show(BuildContext context, PrintOrderModel order) {
    return showDialog<PaymentModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmPaymentDialog(order: order),
    );
  }

  @override
  State<ConfirmPaymentDialog> createState() => _ConfirmPaymentDialogState();
}

class _ConfirmPaymentDialogState extends State<ConfirmPaymentDialog> {
  static final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  final _txnController = TextEditingController();
  late PaymentMethodType _method = widget.order.paymentMethodType;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _txnController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final provider = context.read<PaymentProvider>();
    final result = await provider.confirmPayment(
      widget.order.id,
      _method,
      transactionCode: _method == PaymentMethodType.vietQr
          ? _txnController.text
          : null,
    );
    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(result);
    } else {
      setState(() {
        _submitting = false;
        _error = provider.errorMessage ?? 'Không thể xác nhận thanh toán.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận thanh toán'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.order.orderCode,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Sinh viên: ${widget.order.studentName}'),
            const SizedBox(height: 8),
            Text(
              'Số tiền: ${_currency.format(widget.order.totalPrice)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: PaymentMethodType.values.map((m) {
                return ChoiceChip(
                  avatar: Icon(m.icon, size: 18),
                  label: Text(
                    m == PaymentMethodType.cash ? 'Tiền mặt' : 'Chuyển khoản',
                  ),
                  selected: _method == m,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _method = m),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (_method == PaymentMethodType.vietQr)
              TextField(
                controller: _txnController,
                enabled: !_submitting,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Mã giao dịch ngân hàng',
                  hintText: 'VD: FT26301123456',
                  border: OutlineInputBorder(),
                ),
              )
            else
              const Text(
                'Xác nhận đã thu đủ tiền mặt từ sinh viên.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.statusCancelled)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusCompleted,
            foregroundColor: Colors.white,
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}
