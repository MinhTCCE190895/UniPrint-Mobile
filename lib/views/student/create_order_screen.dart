import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/document_model.dart';
import '../../providers/document_provider.dart';
import '../../providers/order_provider.dart';

import 'components/upload_document_sheet.dart';
import 'my_documents_screen.dart';
import 'order_confirmation_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  final DocumentModel? initialDocument;
  const CreateOrderScreen({super.key, this.initialDocument});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  final _notesController = TextEditingController();

  DocumentModel? _selectedDoc;
  int _copies = 1;
  bool _isColor = false;
  bool _isDoubleSided = false;
  bool _hasBinding = false;
  bool _hasStaple = false;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDocument != null) {
      _selectedDoc = widget.initialDocument;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final docProvider = context.read<DocumentProvider>();
      await docProvider.loadDocuments();
      if (!mounted) return;

      if (_selectedDoc != null) {
        final existing = docProvider.documents
            .where((d) => d.id == _selectedDoc!.id)
            .toList();
        if (existing.isNotEmpty) {
          _selectedDoc = existing.first;
        }
        _triggerPriceCalculation();
      } else if (docProvider.documents.isNotEmpty) {
        setState(() {
          _selectedDoc = docProvider.documents.first;
        });
        _triggerPriceCalculation();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _triggerPriceCalculation() async {
    if (_selectedDoc == null) return;
    setState(() => _isCalculating = true);
    await context.read<OrderProvider>().calculatePriceRealtime(
          pageCount: _selectedDoc!.pageCount,
          numberOfCopies: _copies,
          isColor: _isColor,
          isDoubleSided: _isDoubleSided,
          hasBinding: _hasBinding,
          hasStaple: _hasStaple,
        );
    if (mounted) setState(() => _isCalculating = false);
  }

  /// BR02: Không gọi API tạo đơn trực tiếp từ đây.
  /// Chuyển sang OrderConfirmationScreen để người dùng review + xác nhận.
  void _handleProceedToConfirmation() {
    if (_selectedDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tài liệu cần in')),
      );
      return;
    }

    final estimatedPrice = context.read<OrderProvider>().estimatedPrice;
    if (estimatedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tính giá, vui lòng chờ vài giây rồi thử lại...'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          document: _selectedDoc!,
          numberOfCopies: _copies,
          isColor: _isColor,
          isDoubleSided: _isDoubleSided,
          hasBinding: _hasBinding,
          hasStaple: _hasStaple,
          estimatedPrice: estimatedPrice,
          notes: _notesController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _handleUploadDocument() async {
    final newDoc = await UploadDocumentSheet.show(context);
    if (newDoc != null && mounted) {
      setState(() {
        _selectedDoc = newDoc;
      });
      _triggerPriceCalculation();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đã chọn tài liệu "${newDoc.fileName}" (${newDoc.pageCount} trang)'),
          backgroundColor: AppColors.statusCompleted,
        ),
      );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_shared_outlined),
            tooltip: 'Kho tài liệu',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyDocumentsScreen()),
            ),
          ),
        ],
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
                const Text(
                  '1. Chọn tài liệu',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('Quản lý'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyDocumentsScreen()),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tải lên mới'),
                      onPressed: _handleUploadDocument,
                    ),
                  ],
                ),
              ],
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: docProvider.documents.isEmpty
                    ? ListTile(
                        leading: const Icon(Icons.upload_file,
                            color: AppColors.primary),
                        title: const Text('Chưa có tài liệu nào'),
                        subtitle: const Text(
                            'Nhấn "Tải lên mới" để thêm tài liệu PDF/Word cần in'),
                        trailing: ElevatedButton(
                          onPressed: _handleUploadDocument,
                          child: const Text('Tải lên'),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<DocumentModel>(
                          isExpanded: true,
                          value: _selectedDoc,
                          items: docProvider.documents.map((doc) {
                            return DropdownMenuItem<DocumentModel>(
                              value: doc,
                              child: Text(
                                  '${doc.fileName} (${doc.pageCount} trang)'),
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
            const Text(
              '2. Tùy chọn in ấn',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                        Text(
                          '$_copies',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
            const SizedBox(height: 16),

            // Section 2b: Notes
            const Text(
              '3. Ghi chú cho nhân viên (tuỳ chọn)',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'VD: In từ trang 5 đến 20, giấy A4...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Section 3: Price Preview — Task 8: Tính giá realtime
            Row(
              children: [
                const Text(
                  '4. Dự tính chi phí',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                if (_isCalculating) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Card(
              color: AppColors.primary.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _isCalculating
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.primaryLight,
                  width: 1.2,
                ),
              ),
              child: AnimatedOpacity(
                opacity: _isCalculating ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _priceRow(
                        label: 'Đơn giá mỗi trang:',
                        value: estimatedPrice?.unitPricePerPage,
                        fallback: 0,
                      ),
                      const SizedBox(height: 6),
                      _priceRow(
                        label:
                            'Tiền trang in (${_selectedDoc?.pageCount ?? 0}tr × $_copies bản):',
                        value: estimatedPrice?.pageSubtotal,
                        fallback: 0,
                      ),
                      const SizedBox(height: 6),
                      _priceRow(
                        label: 'Phí gia công (gáy/ghim):',
                        value: estimatedPrice?.extraServicesTotal,
                        fallback: 0,
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TỔNG DỰ KIẾN:',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                          Text(
                            _currencyFormat.format(
                                estimatedPrice?.totalEstimatedPrice ?? 0),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button — BR02: chuyển sang màn hình xác nhận
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_isCalculating || estimatedPrice == null)
                    ? null
                    : _handleProceedToConfirmation,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Tiếp Tục & Xem Xác Nhận',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
      {required String label, double? value, double fallback = 0}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Text(_currencyFormat.format(value ?? fallback)),
      ],
    );
  }
}
