import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/payment_model.dart';
import '../../../providers/payment_provider.dart';

/// Task 18: Hóa đơn thanh toán của sinh viên — chọn Tiền mặt / VietQR và hiển thị mã chuyển khoản.
class PaymentSection extends StatefulWidget {
  final String orderId;

  /// Đơn đã hủy thì chỉ xem, không cho chọn phương thức.
  final bool allowChangeMethod;

  const PaymentSection({
    super.key,
    required this.orderId,
    this.allowChangeMethod = true,
  });

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection> {
  static final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<PaymentProvider>().loadPayment(widget.orderId);
    if (mounted) setState(() => _loadedOnce = true);
  }

  Future<void> _select(PaymentMethodType method) async {
    final provider = context.read<PaymentProvider>();
    final result = await provider.selectMethod(widget.orderId, method);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không thể đổi phương thức.'),
          backgroundColor: AppColors.statusCancelled,
        ),
      );
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã sao chép $label')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final payment = provider.paymentOf(widget.orderId);
    final busy = provider.isBusy(widget.orderId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: payment == null
            ? _buildPlaceholder(busy || !_loadedOnce, provider.errorMessage)
            : _buildInvoice(payment, busy),
      ),
    );
  }

  Widget _buildPlaceholder(bool loading, String? error) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      children: [
        Text(
          error ?? 'Không tải được hóa đơn.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.statusCancelled),
        ),
        TextButton(onPressed: _load, child: const Text('Thử lại')),
      ],
    );
  }

  Widget _buildInvoice(PaymentModel payment, bool busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hóa đơn thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            _chip(payment.status.label, payment.status.color),
          ],
        ),
        const SizedBox(height: 12),
        _row('Số tiền', _currency.format(payment.amount), bold: true),
        _row('Phương thức', payment.method.label),
        if (payment.transactionCode != null)
          _row('Mã giao dịch', payment.transactionCode!),
        if (payment.paidAt != null)
          _row(
            'Thanh toán lúc',
            DateFormat('HH:mm dd/MM/yyyy').format(payment.paidAt!),
          ),
        if (!payment.isPaid && widget.allowChangeMethod) ...[
          const Divider(height: 24),
          const Text(
            'Chọn cách thanh toán',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaymentMethodType.values.map((m) {
              final selected = payment.method == m;
              return ChoiceChip(
                avatar: Icon(m.icon, size: 18),
                label: Text(m.label),
                selected: selected,
                onSelected: busy || selected ? null : (_) => _select(m),
              );
            }).toList(),
          ),
          if (busy) const LinearProgressIndicator(minHeight: 2),
        ],
        if (payment.canShowVietQr) _buildVietQr(payment.vietQr!),
        if (!payment.isPaid && payment.method == PaymentMethodType.cash)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Thanh toán tiền mặt tại quầy khi đến nhận tài liệu.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildVietQr(VietQrInfo qr) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              key: const Key('vietqr-image'),
              data: qr.qrPayload,
              version: QrVersions.auto,
              size: 200,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mở app ngân hàng và quét mã để chuyển khoản',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        _row('Ngân hàng', qr.bankName),
        _row(
          'Số tài khoản',
          qr.accountNo,
          onCopy: () => _copy('số tài khoản', qr.accountNo),
        ),
        _row('Chủ tài khoản', qr.accountName),
        _row(
          'Nội dung CK',
          qr.transferContent,
          bold: true,
          onCopy: () => _copy('nội dung chuyển khoản', qr.transferContent),
        ),
        const SizedBox(height: 4),
        const Text(
          'Giữ nguyên nội dung chuyển khoản. Nhân viên sẽ xác nhận khi nhận được tiền.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
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
          if (onCopy != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy, size: 16),
              tooltip: 'Sao chép',
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
}
