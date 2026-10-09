import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/order_provider.dart';

class StaffQrScannerScreen extends StatefulWidget {
  const StaffQrScannerScreen({super.key});

  @override
  State<StaffQrScannerScreen> createState() => _StaffQrScannerScreenState();
}

class _StaffQrScannerScreenState extends State<StaffQrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualInputController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  Future<void> _handleQrDetected(String qrToken) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

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
              Text('Mã đơn: ${completedOrder.orderCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Sinh viên: ${completedOrder.studentName}'),
              Text('Tài liệu: ${completedOrder.documentName}'),
              const SizedBox(height: 8),
              const Text('Đơn hàng đã được đổi sang trạng thái HOÀN THÀNH (Completed).', style: TextStyle(color: AppColors.statusCompleted)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // back to queue
              },
              child: const Text('Xong'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Mã QR không hợp lệ hoặc đã nhận rồi'),
          backgroundColor: AppColors.statusCancelled,
        ),
      );
      setState(() => _isProcessing = false);
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
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
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
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Hoặc nhập mã Token / ID thủ công (dành cho máy ảo không có Camera):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập mã QR Token...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                        onPressed: _isProcessing
                            ? null
                            : () {
                                if (_manualInputController.text.trim().isNotEmpty) {
                                  _handleQrDetected(_manualInputController.text.trim());
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
        ],
      ),
    );
  }
}
