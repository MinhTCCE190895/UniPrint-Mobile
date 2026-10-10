import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/print_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../auth/login_screen.dart';
import 'staff_qr_scanner_screen.dart';

class StaffQueueScreen extends StatefulWidget {
  const StaffQueueScreen({super.key});

  @override
  State<StaffQueueScreen> createState() => _StaffQueueScreenState();
}

class _StaffQueueScreenState extends State<StaffQueueScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadStaffQueue();
    });
  }

  Future<void> _changeStatus(String orderId, int newStatus) async {
    final success = await context.read<OrderProvider>().updateStatus(orderId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Cập nhật trạng thái thành công' : 'Lỗi cập nhật trạng thái'),
          backgroundColor: success ? AppColors.statusCompleted : AppColors.statusCancelled,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản nhân viên không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCancelled, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Hàng Đợi In Ấn (Staff)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('Nhân viên: ${auth.currentUser?.fullName ?? "Staff"}', style: const TextStyle(fontSize: 12, color: Colors.white70)),]),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Quét mã giao tài liệu',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffQrScannerScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.loadStaffQueue(),
        child: orderProvider.isLoading && orderProvider.staffQueue.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orderProvider.staffQueue.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist_rtl_rounded, size: 64, color: AppColors.textLight),
                        SizedBox(height: 12),
                        Text('Hiện không có đơn nào trong hàng đợi', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.white,
                        child: Row(
                          children: [
                            const Icon(Icons.sort_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Hàng đợi in (FIFO - Ưu tiên đơn trước)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Text(
                                '${orderProvider.staffQueue.length} đơn chờ',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: orderProvider.staffQueue.length,
                          itemBuilder: (context, index) {
                            final order = orderProvider.staffQueue[index];
                            final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(order.createdAt);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: AppColors.primary,
                                              child: Text(
                                                '#${index + 1}',
                                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              order.orderCode,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: order.status.color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: order.status.color),
                                          ),
                                          child: Text(
                                            order.status.label,
                                            style: TextStyle(color: order.status.color, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Sinh viên: ${order.studentName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('Tài liệu: ${order.documentName}', style: const TextStyle(color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text('Thời gian đặt: $timeStr', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${order.numberOfCopies} bản • ${order.isColor ? "Màu" : "Đen trắng"} • ${order.isDoubleSided ? "2 mặt" : "1 mặt"} • ${_currencyFormat.format(order.totalPrice)}',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Chuyển trạng thái:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      if (order.status == OrderStatus.pending)
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.statusProcessing,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          onPressed: () => _changeStatus(order.id, 2),
                                          child: const Text('Nhận in', style: TextStyle(fontSize: 12)),
                                        ),
                                      if (order.status == OrderStatus.processing)
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.statusPrinting,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          onPressed: () => _changeStatus(order.id, 3),
                                          child: const Text('Đang in', style: TextStyle(fontSize: 12)),
                                        ),
                                      if (order.status == OrderStatus.printing)
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.statusReady,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          onPressed: () => _changeStatus(order.id, 5),
                                          child: const Text('Sẵn sàng', style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Quét QR Trả Đơn'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StaffQrScannerScreen()),
        ),
      ),
    );
  }
}
