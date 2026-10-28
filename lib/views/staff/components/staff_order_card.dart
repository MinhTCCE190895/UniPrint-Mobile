import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/print_order_model.dart';

/// Component thẻ hiển thị 1 đơn in trong hàng đợi Staff
class StaffOrderCard extends StatelessWidget {
  final PrintOrderModel order;
  final int queueIndex;
  final void Function(
    PrintOrderModel order,
    int targetStatus,
    String actionTitle,
    String actionDescription,
  ) onStatusChange;
  final void Function(PrintOrderModel order)? onAssignShelf;

  /// Task 18: Thu tiền mặt / xác nhận chuyển khoản cho đơn chưa thanh toán.
  final void Function(PrintOrderModel order)? onConfirmPayment;

  const StaffOrderCard({
    super.key,
    required this.order,
    required this.queueIndex,
    required this.onStatusChange,
    this.onAssignShelf,
    this.onConfirmPayment,
  });

  static final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Số thứ tự FIFO, Mã đơn & Badge trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '#$queueIndex',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.orderCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: order.status.color),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      color: order.status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Thông tin sinh viên & tài liệu
            Text(
              'Sinh viên: ${order.studentName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              'Tài liệu: ${order.documentName}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),

            // Thời gian đặt (FIFO)
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Thời gian đặt: $timeStr',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Thông số cấu hình in & Tổng tiền
            Text(
              '${order.numberOfCopies} bản • ${order.isColor ? "In màu" : "Đen trắng"} • ${order.isDoubleSided ? "2 mặt" : "1 mặt"} • ${_currencyFormat.format(order.totalPrice)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 6),
            _buildPaymentBadge(),

            if (order.shelfCode != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shelves, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'Kệ lưu trữ: ${order.shelfCode}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 20),

            // Hàng nút hành động chuyển đổi trạng thái (State Transition Actions)
            _buildActionRow(context),
          ],
        ),
      ),
    );
  }

  /// Task 18: Hiển thị trạng thái thanh toán của đơn.
  Widget _buildPaymentBadge() {
    final status = order.paymentStatusType;
    return Row(
      children: [
        Icon(
          order.isPaid ? Icons.verified_outlined : Icons.account_balance_wallet_outlined,
          size: 14,
          color: status.color,
        ),
        const SizedBox(width: 4),
        Text(
          order.isPaid
              ? status.label
              : '${status.label} • ${order.paymentMethodType.label}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: status.color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    switch (order.status) {
      case OrderStatus.pending:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusProcessing,
                side: const BorderSide(color: AppColors.statusProcessing),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () => onStatusChange(
                order,
                OrderStatus.processing.value,
                'Tiếp nhận đơn',
                'Xác nhận tiếp nhận đơn in này vào danh sách chuẩn bị in?',
              ),
              child: const Text('Tiếp nhận đơn', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusPrinting,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () => onStatusChange(
                order,
                OrderStatus.printing.value,
                'Bắt đầu in ngay',
                'Xác nhận chuyển thẳng sang in ấn cho đơn hàng này?',
              ),
              child: const Text('Bắt đầu in', style: TextStyle(fontSize: 12)),
            ),
          ],
        );

      case OrderStatus.processing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đang chuẩn bị...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print, size: 14),
              label: const Text('Bắt đầu in', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusPrinting,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              onPressed: () => onStatusChange(
                order,
                OrderStatus.printing.value,
                'Bắt đầu in',
                'Xác nhận đưa tài liệu vào máy in?',
              ),
            ),
          ],
        );

      case OrderStatus.printing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đang chạy máy in...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.statusPrinting,
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(
                onAssignShelf != null
                    ? Icons.shelves
                    : Icons.check_circle_outline,
                size: 14,
              ),
              label: Text(
                onAssignShelf != null ? 'In xong & Xếp kệ' : 'Đã in xong',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusReady,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              onPressed: () {
                if (onAssignShelf != null) {
                  onAssignShelf!(order);
                } else {
                  onStatusChange(
                    order,
                    OrderStatus.readyForPickup.value,
                    'Hoàn tất in ấn',
                    'Xác nhận tài liệu đã in xong và sẵn sàng cho sinh viên nhận?',
                  );
                }
              },
            ),
          ],
        );

      case OrderStatus.readyForPickup:
      case OrderStatus.shelfAssigned:
        if (order.shelfCode == null && onAssignShelf != null) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.statusReady.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: AppColors.statusReady),
                    SizedBox(width: 6),
                    Text(
                      'Đã in xong • Chưa có kệ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusReady,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.shelves, size: 14),
                label: const Text('Xếp kệ', style: TextStyle(fontSize: 12)),
                onPressed: () => onAssignShelf!(order),
              ),
            ],
          );
        }
        if (!order.isPaid && onConfirmPayment != null) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Đã in xong • Thu tiền khi sinh viên đến nhận',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusReady,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.point_of_sale, size: 14),
                label: const Text('Thu tiền', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusCompleted,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                onPressed: () => onConfirmPayment!(order),
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.statusReady.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  size: 16, color: AppColors.statusReady),
              const SizedBox(width: 6),
              Text(
                order.shelfCode != null
                    ? 'Đã xếp kệ ${order.shelfCode} • Chờ sinh viên quét QR nhận'
                    : 'Đã in xong • Chờ sinh viên quét QR nhận',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusReady,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
