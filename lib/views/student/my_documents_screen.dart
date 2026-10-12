import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/document_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import 'components/upload_document_sheet.dart';
import 'create_order_screen.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, PDF, DOCX

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments();
    });
  }

  Future<void> _handleDelete(DocumentModel doc) async {
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.currentUser?.id;

    if (!doc.isOwner(currentUserId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ chủ sở hữu tài liệu mới có quyền xóa.'),
          backgroundColor: AppColors.statusCancelled,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn xóa vĩnh viễn tài liệu "${doc.fileName}"?'),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Chỉ chủ sở hữu tài liệu mới có thể xóa. Thao tác này không thể hoàn tác.',
              style: TextStyle(fontSize: 12, color: AppColors.statusCancelled),
            ),
          ],
        ),
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
            child: const Text('Xóa tài liệu'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final docProvider = context.read<DocumentProvider>();
      final success = await docProvider.deleteDocument(doc.id, currentUserId: currentUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Đã xóa tài liệu "${doc.fileName}" thành công'
                : (docProvider.errorMessage ?? 'Không thể xóa tài liệu')),
            backgroundColor: success ? AppColors.statusCompleted : AppColors.statusCancelled,
          ),
        );
      }
    }
  }

  Future<void> _showUploadSheet() async {
    final newDoc = await UploadDocumentSheet.show(context);
    if (newDoc != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tải lên "${newDoc.fileName}" thành công! (${newDoc.pageCount} trang, ${newDoc.formattedSize})'),
          backgroundColor: AppColors.statusCompleted,
          action: SnackBarAction(
            label: 'Đặt In',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateOrderScreen(initialDocument: newDoc)),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.currentUser?.id;

    var filteredList = docProvider.documents.where((doc) {
      final matchQuery = doc.fileName.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchQuery) return false;

      if (_selectedFilter == 'PDF') return doc.isPdf;
      if (_selectedFilter == 'DOCX') return doc.isWord;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kho Tài Liệu Cá Nhân', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Tải tài liệu mới',
            onPressed: _showUploadSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => docProvider.loadDocuments(),
        child: Column(
          children: [
            // Header stats & search bar
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên tài liệu...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilterChip(
                        label: Text('Tất cả (${docProvider.documents.length})'),
                        selected: _selectedFilter == 'ALL',
                        onSelected: (_) => setState(() => _selectedFilter = 'ALL'),
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('PDF (${docProvider.documents.where((d) => d.isPdf).length})'),
                        selected: _selectedFilter == 'PDF',
                        onSelected: (_) => setState(() => _selectedFilter = 'PDF'),
                        selectedColor: AppColors.statusCancelled.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.statusCancelled,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Word (${docProvider.documents.where((d) => d.isWord).length})'),
                        selected: _selectedFilter == 'DOCX',
                        onSelected: (_) => setState(() => _selectedFilter = 'DOCX'),
                        selectedColor: AppColors.primaryLight.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Document list
            Expanded(
              child: docProvider.isLoading && docProvider.documents.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open_outlined,
                                size: 64,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Không tìm thấy tài liệu phù hợp'
                                    : 'Chưa có tài liệu nào trong kho cá nhân',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.cloud_upload),
                                label: const Text('Tải lên tài liệu PDF / Word'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _showUploadSheet,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final doc = filteredList[index];
                            final isOwner = doc.isOwner(currentUserId);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // File format icon
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: doc.isPdf
                                            ? AppColors.statusCancelled.withValues(alpha: 0.12)
                                            : AppColors.primaryLight.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        doc.isPdf ? Icons.picture_as_pdf : Icons.description,
                                        color: doc.isPdf ? AppColors.statusCancelled : AppColors.primaryLight,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // File metadata
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doc.fileName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${doc.pageCount} trang',
                                                  style: const TextStyle(
                                                    color: AppColors.secondary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.border),
                                                ),
                                                child: Text(
                                                  doc.formattedSize,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ngày tải: ${doc.formattedCreatedAt}',
                                            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              // Print action
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.primary,
                                                  side: const BorderSide(color: AppColors.primary),
                                                  visualDensity: VisualDensity.compact,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                ),
                                                icon: const Icon(Icons.print, size: 16),
                                                label: const Text('Đặt in', style: TextStyle(fontSize: 12)),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => CreateOrderScreen(initialDocument: doc),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const Spacer(),
                                              // Delete action (Owner only)
                                              if (isOwner)
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: AppColors.statusCancelled),
                                                  tooltip: 'Xóa tài liệu',
                                                  onPressed: () => _handleDelete(doc),
                                                )
                                              else
                                                const Tooltip(
                                                  message: 'Chỉ chủ sở hữu mới được xóa',
                                                  child: Icon(Icons.lock_outline, size: 20, color: AppColors.textLight),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tải Tài Liệu'),
        onPressed: _showUploadSheet,
      ),
    );
  }
}
