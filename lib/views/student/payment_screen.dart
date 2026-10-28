import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/print_order_model.dart';
import '../../providers/payment_provider.dart';
import 'components/payment_section.dart';

/// Task 18: Màn hình thanh toán đơn in (tiền mặt khi nhận hoặc chuyển khoản VietQR).
class PaymentScreen extends StatelessWidget {
  final PrintOrderModel order;
  const PaymentScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Thanh toán ${order.orderCode}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<PaymentProvider>().loadPayment(order.id),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              order.documentName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            PaymentSection(
              orderId: order.id,
              allowChangeMethod: order.status != OrderStatus.cancelled,
            ),
          ],
        ),
      ),
    );
  }
}
