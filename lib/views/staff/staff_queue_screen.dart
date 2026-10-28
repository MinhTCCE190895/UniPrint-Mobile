import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/print_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../auth/login_screen.dart';
import 'components/assign_shelf_dialog.dart';
import 'components/confirm_payment_dialog.dart';
import 'components/confirm_status_dialog.dart';
import 'components/staff_order_card.dart';
import 'staff_qr_scanner_screen.dart';
import 'staff_shelves_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/price_config_screen.dart';

/// Màn hình quản lý hàng đợi in ấn dành cho nhân viên (Staff Queue)
/// Hỗ trợ 2 Tab: Đang chờ xử lý in & Đã in xong (Chờ lấy)
class StaffQueueScreen extends StatefulWidget {
  const StaffQueueScreen({super.key});

  @override
  State<StaffQueueScreen> createState() => _StaffQueueScreenState();
}

class _StaffQueueScreenState extends State<StaffQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadStaffQueue();
    });
  }

  /// Mở hộp thoại xác nhận và thực hiện đổi trạng thái in
  void _onStatusChange(
    PrintOrderModel order,
    int targetStatus,
    String actionTitle,
    String actionDescription,
  ) {
    ConfirmStatusDialog.show(
      context: context,
      order: order,
      targetStatus: targetStatus,
      actionTitle: actionTitle,
      actionDescription: actionDescription,
      onConfirm: () async {
        final result = await context
            .read<OrderProvider>()
            .updateStatus(order.id, targetStatus);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.success
                  ? AppColors.statusCompleted
                  : AppColors.statusCancelled,
            ),
          );
        }
      },
    );
  }

  /// Mở hộp thoại gán đơn vào kệ lưu trữ
  void _onAssignShelf(PrintOrderModel order) {
    AssignShelfDialog.show(
      context: context,
      order: order,
      onAssigned: () {
        context.read<OrderProvider>().loadStaffQueue();
      },
    );
  }

  /// Task 18: Thu tiền mặt / xác nhận chuyển khoản rồi tải lại hàng đợi.
  Future<void> _onConfirmPayment(PrintOrderModel order) async {
    final payment = await ConfirmPaymentDialog.show(context, order);
    if (payment == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${order.orderCode}: ${payment.status.label} (${payment.method.label})'),
        backgroundColor: AppColors.statusCompleted,
      ),
    );
    await context.read<OrderProvider>().loadStaffQueue();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản nhân viên?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCancelled,
              foregroundColor: Colors.white,
            ),
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

    final pendingOrders = orderProvider.queuePendingOrders;
    final readyOrders = orderProvider.queueReadyOrders;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hàng Đợi In Ấn (Staff)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Nhân viên: ${auth.currentUser?.fullName ?? "Staff"}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            // Task 20: chỉ Admin thấy nút cấu hình bảng giá
            if (auth.currentUser?.isAdmin ?? false)
              IconButton(
                icon: const Icon(Icons.price_change_outlined),
                tooltip: 'Cấu hình bảng giá',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PriceConfigScreen()),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.shelves),
              tooltip: 'Quản lý kệ lưu trữ',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffShelvesScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: 'Thông tin cá nhân',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
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
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions, size: 18),
                    const SizedBox(width: 6),
                    const Text('Chờ xử lý in'),
                    const SizedBox(width: 6),
                    _buildCountBadge(pendingOrders.length, isWarning: true),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 6),
                    const Text('Đã in xong'),
                    const SizedBox(width: 6),
                    _buildCountBadge(readyOrders.length, isWarning: false),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Danh sách đơn đang chờ xử lý in
            _buildOrderList(
              orders: pendingOrders,
              isLoading: orderProvider.isLoading,
              onRefresh: () => orderProvider.loadStaffQueue(),
              emptyMessage: 'Hiện không có đơn nào đang chờ in',
              emptyIcon: Icons.checklist_rtl_rounded,
            ),

            // Tab 2: Danh sách đơn đã in xong (chờ sinh viên đến lấy)
            _buildOrderList(
              orders: readyOrders,
              isLoading: orderProvider.isLoading,
              onRefresh: () => orderProvider.loadStaffQueue(),
              emptyMessage: 'Chưa có đơn nào đã in xong chờ lấy',
              emptyIcon: Icons.inventory_2_outlined,
            ),
          ],
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
      ),
    );
  }

  Widget _buildCountBadge(int count, {required bool isWarning}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isWarning ? Colors.amber.shade700 : AppColors.statusCompleted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderList({
    required List<PrintOrderModel> orders,
    required bool isLoading,
    required Future<void> Function() onRefresh,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isLoading && orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(emptyIcon, size: 64, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          Text(
                            emptyMessage,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return StaffOrderCard(
                      order: order,
                      queueIndex: index + 1,
                      onStatusChange: _onStatusChange,
                      onAssignShelf: _onAssignShelf,
                      onConfirmPayment: _onConfirmPayment,
                    );
                  },
                ),
    );
  }
}
