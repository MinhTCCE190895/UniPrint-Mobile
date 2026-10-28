import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/document_model.dart';
import '../../models/print_order_model.dart';
import '../../providers/order_provider.dart';
import 'order_success_screen.dart';

/// BR02 — Màn hình xác nhận đơn in trước khi submit.
/// Hiển thị toàn bộ cấu hình + giá dự tính chốt theo bảng giá hiện tại.
/// Sau khi người dùng bấm "Xác nhận & Đặt in", hệ thống gọi API tạo đơn,
/// server trả về [PrintOrderModel] với [orderCode] = ORD-... và [totalPrice] chốt cố định.
class OrderConfirmationScreen extends StatefulWidget {
  final DocumentModel document;
  final int numberOfCopies;
  final bool isColor;
  final bool isDoubleSided;
  final bool hasBinding;
  final bool hasStaple;
  final PriceCalculationResult estimatedPrice;
  final String notes;

  const OrderConfirmationScreen({
    super.key,
    required this.document,
    required this.numberOfCopies,
    required this.isColor,
    required this.isDoubleSided,
    required this.hasBinding,
    required this.hasStaple,
    required this.estimatedPrice,
    required this.notes,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final orderProvider = context.read<OrderProvider>();
    final newOrder = await orderProvider.createOrder(
      documentId: widget.document.id,
      numberOfCopies: widget.numberOfCopies,
      isColor: widget.isColor,
      isDoubleSided: widget.isDoubleSided,
      hasBinding: widget.hasBinding,
      hasStaple: widget.hasStaple,
      notes: widget.notes.isEmpty ? null : widget.notes,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (newOrder != null) {
      // BR02: Đơn đã được tạo, mã ORD-... và totalPrice chốt cố định từ server
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: newOrder),
        ),
      );
    } else {
      final errMsg =
          orderProvider.errorMessage ?? 'Không thể tạo đơn in. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: AppColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final price = widget.estimatedPrice;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Xác Nhận Đơn In'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header notice ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primaryLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng kiểm tra lại thông tin trước khi xác nhận. '
                      'Giá chốt cố định theo bảng giá hiện tại.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primaryLight.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Tài liệu ──────────────────────────────────────
            _sectionTitle('📄 Tài liệu in'),
            _infoCard([
              _infoRow(
                Icons.description_outlined,
                'Tên file',
                doc.fileName,
                bold: true,
              ),
              _infoRow(
                Icons.article_outlined,
                'Số trang',
                '${doc.pageCount} trang',
              ),
              _infoRow(
                Icons.data_usage_outlined,
                'Kích thước',
                doc.formattedSize,
              ),
            ]),
            const SizedBox(height: 16),

            // ── Section: Tùy chọn in ──────────────────────────────────
            _sectionTitle('⚙️ Tùy chọn in ấn'),
            _infoCard([
              _infoRow(
                Icons.copy_outlined,
                'Số bản in',
                '${widget.numberOfCopies} bản',
                bold: true,
              ),
              _infoRow(
                Icons.color_lens_outlined,
                'Màu sắc',
                widget.isColor ? 'In màu' : 'In đen trắng',
                highlight: widget.isColor,
              ),
              _infoRow(
                Icons.flip_outlined,
                'Mặt in',
                widget.isDoubleSided ? 'In 2 mặt (tiết kiệm 20%)' : 'In 1 mặt',
                highlight: widget.isDoubleSided,
              ),
              _infoRow(
                Icons.book_outlined,
                'Đóng gáy',
                widget.hasBinding ? 'Có (+5.000đ)' : 'Không',
                highlight: widget.hasBinding,
              ),
              _infoRow(
                Icons.push_pin_outlined,
                'Bấm kim',
                widget.hasStaple ? 'Có (+1.000đ)' : 'Không',
                highlight: widget.hasStaple,
              ),
              if (widget.notes.isNotEmpty)
                _infoRow(
                  Icons.notes_outlined,
                  'Ghi chú',
                  widget.notes,
                ),
            ]),
            const SizedBox(height: 16),

            // ── Section: Chi phí dự tính BR02 ─────────────────────────
            _sectionTitle('💰 Chi phí (theo bảng giá hiện tại)'),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: AppColors.secondary,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _priceDetailRow(
                      'Đơn giá / trang:',
                      _currencyFormat.format(price.unitPricePerPage),
                    ),
                    const SizedBox(height: 6),
                    _priceDetailRow(
                      'Tiền trang in '
                      '(${doc.pageCount}tr × ${widget.numberOfCopies} bản):',
                      _currencyFormat.format(price.pageSubtotal),
                    ),
                    const SizedBox(height: 6),
                    _priceDetailRow(
                      'Phí gia công (gáy / ghim):',
                      _currencyFormat.format(price.extraServicesTotal),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TỔNG THANH TOÁN:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          _currencyFormat
                              .format(price.totalEstimatedPrice),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '* Giá này sẽ được chốt cố định khi bạn xác nhận đặt in.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting ? 'Đang tạo đơn...' : 'Xác Nhận & Đặt In',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Quay lại chỉnh sửa'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool bold = false,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppColors.secondary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
