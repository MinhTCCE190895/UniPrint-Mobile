import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/document_model.dart';
import '../../providers/document_provider.dart';
import '../../providers/order_provider.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  DocumentModel? _selectedDoc;
  int _copies = 1;
  bool _isColor = false;
  bool _isDoubleSided = false;
  bool _hasBinding = false;
  bool _hasStaple = false;
  final String _notes = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final docProvider = context.read<DocumentProvider>();
      await docProvider.loadDocuments();
      if (docProvider.documents.isNotEmpty && mounted) {
        setState(() {
          _selectedDoc = docProvider.documents.first;
        });
        _triggerPriceCalculation();
      }
    });
  }

  void _triggerPriceCalculation() {
    if (_selectedDoc == null) return;
    context.read<OrderProvider>().calculatePriceRealtime(
      pageCount: _selectedDoc!.pageCount,
      numberOfCopies: _copies,
      isColor: _isColor,
      isDoubleSided: _isDoubleSided,
      hasBinding: _hasBinding,
      hasStaple: _hasStaple,
    );
  }

  Future<void> _handleCreateOrder() async {
    if (_selectedDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tài liệu cần in')),
      );
      return;
    }

    final orderProvider = context.read<OrderProvider>();
    final newOrder = await orderProvider.createOrder(
      documentId: _selectedDoc!.id,
      numberOfCopies: _copies,
      isColor: _isColor,
      isDoubleSided: _isDoubleSided,
      hasBinding: _hasBinding,
      hasStaple: _hasStaple,
      notes: _notes,
    );

    if (!mounted) return;

    if (newOrder != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tạo đơn in ${newOrder.orderCode} thành công!'),
          backgroundColor: AppColors.statusCompleted,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Không thể tạo đơn in'),
          backgroundColor: AppColors.statusCancelled,
        ),
      );
    }
  }

  Future<void> _showQuickUploadDialog() async {
    final fileNameController = TextEditingController(text: 'Bai_Tap_Tuan_3.pdf');
    final pagesController = TextEditingController(text: '12');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm tài liệu mô phỏng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fileNameController,
              decoration: const InputDecoration(labelText: 'Tên file', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số trang', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (created == true && mounted) {
      final doc = await context.read<DocumentProvider>().uploadMeta(
        fileName: fileNameController.text.trim(),
        fileExtension: '.pdf',
        fileSizeBytes: 1024 * 500,
        pageCount: int.tryParse(pagesController.text) ?? 1,
      );
      if (doc != null && mounted) {
        setState(() {
          _selectedDoc = doc;
        });
        _triggerPriceCalculation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final estimatedPrice = orderProvider.estimatedPrice;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cấu Hình & Đặt In'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Choose Document
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('1. Chọn tài liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tải lên mới'),
                  onPressed: _showQuickUploadDialog,
                ),
              ],
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: docProvider.documents.isEmpty
                    ? ListTile(
                        leading: const Icon(Icons.upload_file, color: AppColors.primary),
                        title: const Text('Chưa có tài liệu nào'),
                        subtitle: const Text('Nhấn "Tải lên mới" để thêm tài liệu cần in'),
                        trailing: ElevatedButton(
                          onPressed: _showQuickUploadDialog,
                          child: const Text('Thêm'),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<DocumentModel>(
                          isExpanded: true,
                          value: _selectedDoc,
                          items: docProvider.documents.map((doc) {
                            return DropdownMenuItem<DocumentModel>(
                              value: doc,
                              child: Text('${doc.fileName} (${doc.pageCount} trang)'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedDoc = val);
                            _triggerPriceCalculation();
                          },
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Print Settings
            const Text('2. Tùy chọn in ấn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Số lượng bản in'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _copies > 1
                              ? () {
                                  setState(() => _copies--);
                                  _triggerPriceCalculation();
                                }
                              : null,
                        ),
                        Text('$_copies', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() => _copies++);
                            _triggerPriceCalculation();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('In màu'),
                    subtitle: const Text('In đen trắng theo mặc định'),
                    value: _isColor,
                    onChanged: (val) {
                      setState(() => _isColor = val);
                      _triggerPriceCalculation();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('In 2 mặt'),
                    subtitle: const Text('Tiết kiệm 20% giấy in'),
                    value: _isDoubleSided,
                    onChanged: (val) {
                      setState(() => _isDoubleSided = val);
                      _triggerPriceCalculation();
                    },
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Đóng gáy lò xo / dập bìa (+5.000đ)'),
                    value: _hasBinding,
                    onChanged: (val) {
                      setState(() => _hasBinding = val ?? false);
                      _triggerPriceCalculation();
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Bấm kim góc (+1.000đ)'),
                    value: _hasStaple,
                    onChanged: (val) {
                      setState(() => _hasStaple = val ?? false);
                      _triggerPriceCalculation();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Price Preview
            const Text('3. Dự tính chi phí (Realtime)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Card(
              color: AppColors.primary.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.primaryLight, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Đơn giá mỗi trang:', style: TextStyle(color: AppColors.textSecondary)),
                        Text(_currencyFormat.format(estimatedPrice?.unitPricePerPage ?? 500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phí dịch vụ gia công:', style: TextStyle(color: AppColors.textSecondary)),
                        Text(_currencyFormat.format(estimatedPrice?.extraServicesTotal ?? 0)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TỔNG TIỀN DỰ KIẾN:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text(
                          _currencyFormat.format(estimatedPrice?.totalEstimatedPrice ?? 0),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: orderProvider.isLoading ? null : _handleCreateOrder,
                child: orderProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Xác Nhận & Đặt In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
