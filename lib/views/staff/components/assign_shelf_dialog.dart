import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/print_order_model.dart';
import '../../../models/shelf_model.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/shelf_provider.dart';

class AssignShelfDialog extends StatefulWidget {
  final PrintOrderModel order;
  final VoidCallback? onAssigned;

  const AssignShelfDialog({
    super.key,
    required this.order,
    this.onAssigned,
  });

  static Future<void> show({
    required BuildContext context,
    required PrintOrderModel order,
    VoidCallback? onAssigned,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AssignShelfDialog(
        order: order,
        onAssigned: onAssigned,
      ),
    );
  }

  @override
  State<AssignShelfDialog> createState() => _AssignShelfDialogState();
}

class _AssignShelfDialogState extends State<AssignShelfDialog> {
  String? _selectedShelfId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShelfProvider>().fetchShelves();
    });
  }

  Future<void> _handleAssign() async {
    if (_selectedShelfId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn một kệ lưu trữ còn chỗ.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final orderProvider = context.read<OrderProvider>();
    final result = await orderProvider.assignShelf(
      widget.order.id,
      _selectedShelfId!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? AppColors.statusCompleted : Colors.red,
      ),
    );

    if (result.success && widget.onAssigned != null) {
      widget.onAssigned!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.shelves, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Xếp Kệ Đơn ${widget.order.orderCode}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Consumer<ShelfProvider>(
          builder: (context, shelfProvider, _) {
            if (shelfProvider.isLoading && shelfProvider.shelves.isEmpty) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final availableShelves =
                shelfProvider.shelves.where((s) => s.isAvailable).toList();

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tài liệu: ${widget.order.documentName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sinh viên: ${widget.order.studentName} • ${widget.order.numberOfCopies} bản',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Chọn kệ lưu trữ còn chỗ:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (availableShelves.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tất cả các kệ hiện đã đầy chỗ hoặc chưa có kệ nào. Vui lòng tạo thêm kệ trước.',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...availableShelves.map((shelf) => _buildShelfRadioTile(shelf)),
                ],
              ),
            );
          },
        ),
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
          ),
          onPressed: _isSubmitting ? null : _handleAssign,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Xác nhận xếp kệ'),
        ),
      ],
    );
  }

  Widget _buildShelfRadioTile(ShelfModel shelf) {
    final isSelected = _selectedShelfId == shelf.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _selectedShelfId = shelf.id;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Kệ ${shelf.shelfCode}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Còn ${shelf.availableSlots} chỗ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đang lưu: ${shelf.currentCount}/${shelf.maxCapacity} đơn • ${shelf.location}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
