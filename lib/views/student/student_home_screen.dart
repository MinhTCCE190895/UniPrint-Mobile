import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/print_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../auth/login_screen.dart';
import 'create_order_screen.dart';
import 'order_qr_screen.dart';
import 'order_tracking_screen.dart';
import 'payment_screen.dart';
import 'my_documents_screen.dart';
import '../profile/profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadMyOrders();
    });
  }

  Future<void> _handleCancel(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn in này không? Chỉ có thể hủy khi đơn chưa được in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Đóng')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCancelled, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final orderProvider = context.read<OrderProvider>();
      final success = await orderProvider.cancelOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Đã hủy đơn thành công'
                : (orderProvider.errorMessage ?? 'Không thể hủy đơn')),
            backgroundColor: success
                ? AppColors.statusCompleted
                : AppColors.statusCancelled,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống không?'),
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

  /// Task 19: Mở màn hình theo dõi chi tiết đơn, quay lại thì tải lại danh sách.
  Future<void> _openTracking(PrintOrderModel order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(orderId: order.id, orderCode: order.orderCode),
      ),
    );
    if (mounted) context.read<OrderProvider>().loadMyOrders();
  }

  /// Task 18: Trạng thái thanh toán + lối vào màn hình thanh toán (Cash / VietQR).
  Widget _buildPaymentRow(PrintOrderModel order) {
    final status = order.paymentStatusType;
    return Row(
      children: [
        Icon(
          order.isPaid ? Icons.verified_outlined : Icons.account_balance_wallet_outlined,
          size: 16,
          color: status.color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            order.isPaid ? status.label : '${status.label} • ${order.paymentMethodType.label}',
            style: TextStyle(color: status.color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaymentScreen(order: order)),
            );
            if (mounted) context.read<OrderProvider>().loadMyOrders();
          },
          child: Text(order.isPaid ? 'Xem hóa đơn' : 'Thanh toán', style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UniPrint Mobile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Xin chào, ${auth.currentUser?.fullName ?? 'Sinh viên'}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Thông tin cá nhân',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_shared_outlined),
            tooltip: 'Kho tài liệu cá nhân',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyDocumentsScreen()),
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
        onRefresh: () => orderProvider.loadMyOrders(),
        child: orderProvider.isLoading && orderProvider.myOrders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orderProvider.myOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 64, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        const Text('Bạn chưa có đơn in nào', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.folder_shared_outlined),
                              label: const Text('Kho tài liệu'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MyDocumentsScreen()),
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Tạo đơn in mới'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orderProvider.myOrders.length,
                    itemBuilder: (context, index) {
                      final order = orderProvider.myOrders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        // Task 19: chạm vào thẻ để xem chi tiết theo dõi đơn
                        child: InkWell(
                          onTap: () => _openTracking(order),
                          child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderCode,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
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
                              const SizedBox(height: 8),
                              Text(
                                order.documentName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.numberOfCopies} bản • ${order.isColor ? "In màu" : "In đen trắng"} • ${order.isDoubleSided ? "2 mặt" : "1 mặt"}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              if (order.shelfCode != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.shelves, size: 16, color: AppColors.secondary),
                                    const SizedBox(width: 4),
                                    Text('Vị trí nhận: Kệ ${order.shelfCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                  ],
                                ),
                              ],
                              if (order.status != OrderStatus.cancelled) ...[
                                const SizedBox(height: 4),
                                _buildPaymentRow(order),
                              ],
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _currencyFormat.format(order.totalPrice),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  Row(
                                    children: [
                                      if (order.status == OrderStatus.readyForPickup || order.status == OrderStatus.shelfAssigned)
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.qr_code, size: 16),
                                          label: const Text('Mã QR nhận', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => OrderQrScreen(order: order)),
                                          ),
                                        ),
                                      if (order.canCancel) ...[
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.statusCancelled),
                                          onPressed: () => _handleCancel(order.id),
                                          child: const Text('Hủy', style: TextStyle(fontSize: 12)),
                                        ),
                                      ] else if (order.status == OrderStatus.printing) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.statusPrinting.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.statusPrinting.withValues(alpha: 0.4)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.lock_outline, size: 13, color: AppColors.statusPrinting),
                                              SizedBox(width: 4),
                                              Text(
                                                'Đang in, không thể hủy',
                                                style: TextStyle(fontSize: 11, color: AppColors.statusPrinting, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Đặt In Ngay'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
        ),
      ),
    );
  }
}
