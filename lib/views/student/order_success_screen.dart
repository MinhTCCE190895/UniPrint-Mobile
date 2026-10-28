import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/print_order_model.dart';
import 'student_home_screen.dart';

/// BR02 — Màn hình thành công sau khi tạo đơn in.
/// Hiển thị mã đơn ORD-... nổi bật và giá đã chốt cố định từ server.
/// Người dùng không thể thay đổi giá sau bước này.
class OrderSuccessScreen extends StatelessWidget {
  final PrintOrderModel order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final createdAtLocal = order.createdAt.toLocal();
    final dateStr =
        DateFormat('HH:mm - dd/MM/yyyy').format(createdAtLocal);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Đặt In Thành Công'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            // ── Success Icon ───────────────────────────────────────────
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.statusCompleted.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.statusCompleted,
                size: 52,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Đơn in đã được gửi thành công!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // ── Order Code Card (ORD-...) ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2D5BE3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'MÃ ĐƠN IN',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: order.orderCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép mã đơn'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.copy_rounded,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusPending.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.statusPending.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13,
                            color:
                                AppColors.statusPending.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Text(
                          order.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.statusPending
                                .withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Locked Price Card (BR02: giá chốt cố định) ────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.secondary, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded,
                            size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        const Text(
                          'Giá đã chốt cố định',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          currencyFormat.format(order.totalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    _detailRow('📄 Tài liệu:', order.documentName),
                    _detailRow(
                        '📋 Số bản:', '${order.numberOfCopies} bản'),
                    _detailRow(
                        '🎨 Màu sắc:',
                        order.isColor ? 'In màu' : 'In đen trắng'),
                    _detailRow(
                        '↔️ Mặt in:',
                        order.isDoubleSided ? 'In 2 mặt' : 'In 1 mặt'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 13, color: AppColors.secondary),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Giá này đã được chốt cố định và không thay đổi dù bảng giá cập nhật sau.',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.secondary,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Next steps hint ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📌 Các bước tiếp theo:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.primary),
                  ),
                  SizedBox(height: 8),
                  _StepItem(
                      step: '1',
                      text:
                          'Nhân viên sẽ chuẩn bị và in tài liệu của bạn.'),
                  _StepItem(
                      step: '2',
                      text:
                          'Khi đơn "Sẵn sàng lấy", bạn sẽ thấy nút QR nhận tài liệu.'),
                  _StepItem(
                      step: '3',
                      text:
                          'Đưa mã QR cho nhân viên quầy in để xác nhận nhận tài liệu.'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Action buttons ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Về Trang Chủ',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const StudentHomeScreen()),
                  (route) => false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Tạo Đơn In Khác'),
                onPressed: () {
                  // Pop thêm 1 màn hình (OrderConfirmationScreen) để về CreateOrderScreen
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String step;
  final String text;
  const _StepItem({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
