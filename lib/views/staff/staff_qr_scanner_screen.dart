import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';

class StaffQrScannerScreen extends StatefulWidget {
  const StaffQrScannerScreen({super.key});

  @override
  State<StaffQrScannerScreen> createState() => _StaffQrScannerScreenState();
}

class _StaffQrScannerScreenState extends State<StaffQrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualInputController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _setCameraRunning(bool running) async {
    try {
      if (running) {
        await _scannerController.start();
      } else {
        await _scannerController.stop();
      }
    } catch (_) {
      // Manual token entry remains available when the camera cannot start.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _setCameraRunning(state == AppLifecycleState.resumed && !_isProcessing);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  Future<void> _handleQrDetected(String qrToken) async {
    if (_isProcessing) return;
    if (context.read<AuthProvider>().currentUser?.isStaff != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ nhân viên được xác nhận nhận tài liệu.'),
        ),
      );
      return;
    }
    if (qrToken.trim().isEmpty) return;
    setState(() => _isProcessing = true);
    await _setCameraRunning(false);
    if (!mounted) return;

    final orderProvider = context.read<OrderProvider>();
    final completedOrder = await orderProvider.verifyPickup(qrToken);

    if (!mounted) return;

    if (completedOrder != null) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.statusCompleted),
              SizedBox(width: 8),
              Text('Giao tài liệu thành công!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mã đơn: ${completedOrder.orderCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Sinh viên: ${completedOrder.studentName}'),
              Text('Tài liệu: ${completedOrder.documentName}'),
              const SizedBox(height: 8),
              const Text(
                'Đơn hàng đã được đổi sang trạng thái HOÀN THÀNH (Completed).',
                style: TextStyle(color: AppColors.statusCompleted),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Xong'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderProvider.errorMessage ?? 'Mã QR không hợp lệ hoặc đã nhận rồi',
          ),
          backgroundColor: AppColors.statusCancelled,
        ),
      );
      setState(() => _isProcessing = false);
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        await _setCameraRunning(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét QR Xác Nhận Nhận Tài Liệu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  errorBuilder: (context, error) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không thể mở camera. Kiểm tra quyền camera hoặc nhập token bên dưới.',
                      ),
                    ),
                  ),
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      _handleQrDetected(barcodes.first.rawValue!);
                    }
                  },
                ),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Hoặc nhập mã QR Token thủ công:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualInputController,
                            decoration: const InputDecoration(
                              hintText: 'Nhập mã QR Token...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  if (_manualInputController.text
                                      .trim()
                                      .isNotEmpty) {
                                    _handleQrDetected(
                                      _manualInputController.text.trim(),
                                    );
                                  }
                                },
                          child: const Text('Xác nhận'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
