import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/print_order_model.dart';

/// Hộp thoại xác nhận chuyển đổi trạng thái in ấn
class ConfirmStatusDialog extends StatefulWidget {
  final PrintOrderModel order;
  final int targetStatus;
  final String actionTitle;
  final String actionDescription;
  final Future<void> Function() onConfirm;

  const ConfirmStatusDialog({
    super.key,
    required this.order,
    required this.targetStatus,
    required this.actionTitle,
    required this.actionDescription,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required PrintOrderModel order,
    required int targetStatus,
    required String actionTitle,
    required String actionDescription,
    required Future<void> Function() onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmStatusDialog(
        order: order,
        targetStatus: targetStatus,
        actionTitle: actionTitle,
        actionDescription: actionDescription,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ConfirmStatusDialog> createState() => _ConfirmStatusDialogState();
}

class _ConfirmStatusDialogState extends State<ConfirmStatusDialog> {
  bool _isSubmitting = false;

  Future<void> _handleConfirm() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cảnh báo kích hoạt BR02 khi chuyển sang trạng thái Đang in (3)
    final isPrintingStep = widget.targetStatus == OrderStatus.printing.value;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.actionTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.actionDescription,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mã đơn hàng:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                      widget.order.orderCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tài liệu:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Flexible(
                      child: Text(
                        widget.order.documentName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isPrintingStep) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Khi bắt đầu in, hệ thống sẽ khóa quyền hủy đơn của sinh viên.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isSubmitting ? null : _handleConfirm,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}
