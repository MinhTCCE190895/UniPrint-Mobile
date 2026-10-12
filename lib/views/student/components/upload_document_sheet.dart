import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/document_reader_util.dart';
import '../../../models/document_model.dart';
import '../../../providers/document_provider.dart';

class UploadDocumentSheet extends StatefulWidget {
  const UploadDocumentSheet({super.key});

  static Future<DocumentModel?> show(BuildContext context) {
    return showModalBottomSheet<DocumentModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UploadDocumentSheet(),
    );
  }

  @override
  State<UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<UploadDocumentSheet> {
  final _fileNameController = TextEditingController();
  final _pageCountController = TextEditingController();

  PlatformFile? _pickedFile;
  int _detectedPageCount = 1;
  int _fileSizeBytes = 0;
  String _fileExtension = '.pdf';
  String _formattedSize = '0 KB';
  bool _isAnalyzing = false;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fileNameController.dispose();
    _pageCountController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
      _isAnalyzing = true;
    });

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc'],
      );

      if (files.isEmpty) {
        setState(() => _isAnalyzing = false);
        return;
      }

      final file = files.first;
      final meta = await DocumentReaderUtil.readFromPlatformFile(file);

      if (!meta.isSupported) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = meta.errorMessage ?? 'Tệp không được hỗ trợ';
        });
        return;
      }

      setState(() {
        _pickedFile = file;
        _fileExtension = meta.fileExtension;
        _fileSizeBytes = meta.fileSizeBytes;
        _formattedSize = meta.formattedSize;
        _detectedPageCount = meta.pageCount;
        _fileNameController.text = meta.fileName;
        _pageCountController.text = meta.pageCount.toString();
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Lỗi đọc tệp: ${e.toString()}';
      });
    }
  }

  void _loadSampleFile({required bool isDocx}) {
    final fileName = isDocx ? 'Bao_Cao_Do_An_PRN232.docx' : 'Giao_Trinh_Kien_Truc_Phan_Mem.pdf';
    final extension = isDocx ? '.docx' : '.pdf';
    final size = isDocx ? 1024 * 760 : 1024 * 1024 * 2 + 350 * 1024;
    final pages = isDocx ? 18 : 34;

    setState(() {
      _pickedFile = null;
      _errorMessage = null;
      _fileExtension = extension;
      _fileSizeBytes = size;
      _formattedSize = isDocx ? '760 KB' : '2.3 MB';
      _detectedPageCount = pages;
      _fileNameController.text = fileName;
      _pageCountController.text = pages.toString();
    });
  }

  Future<void> _handleUpload() async {
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên tài liệu');
      return;
    }

    final pages = int.tryParse(_pageCountController.text.trim()) ?? _detectedPageCount;
    if (pages <= 0) {
      setState(() => _errorMessage = 'Số trang phải lớn hơn 0');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    final docProvider = context.read<DocumentProvider>();
    List<int>? fileBytes;
    if (_pickedFile != null) {
      try {
        fileBytes = await _pickedFile!.readAsBytes();
      } catch (_) {
        // Fallback to path
      }
    }

    final newDoc = await docProvider.uploadDocument(
      fileName: fileName,
      fileExtension: _fileExtension,
      fileSizeBytes: _fileSizeBytes > 0 ? _fileSizeBytes : 1024 * 250,
      pageCount: pages,
      filePath: _pickedFile?.path,
      fileBytes: fileBytes,
    );

    if (!mounted) return;

    if (newDoc != null) {
      Navigator.pop(context, newDoc);
    } else {
      setState(() {
        _isUploading = false;
        _errorMessage = docProvider.errorMessage ?? 'Không thể tải lên tài liệu';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = _fileExtension.toLowerCase().contains('pdf');
    final hasFile = _fileNameController.text.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tải Lên Tài Liệu Mới',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Hệ thống tự động phát hiện số trang và kích thước file (.PDF / .DOCX)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // File selection button
            InkWell(
              onTap: _isAnalyzing || _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(
                    color: hasFile ? AppColors.secondary : AppColors.primaryLight,
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_isAnalyzing) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text('Đang phân tích cấu trúc tài liệu...'),
                    ] else ...[
                      Icon(
                        hasFile
                            ? (isPdf ? Icons.picture_as_pdf : Icons.description)
                            : Icons.cloud_upload_outlined,
                        size: 44,
                        color: hasFile
                            ? (isPdf ? AppColors.statusCancelled : AppColors.primary)
                            : AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hasFile ? 'Đã chọn tệp: ${_fileNameController.text}' : 'Nhấn để chọn tệp từ thiết bị',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: hasFile ? AppColors.textPrimary : AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasFile ? 'Bấm để thay đổi tệp khác' : 'Hỗ trợ định dạng PDF, Word (DOCX)',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Quick Samples Option
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Mẫu nhanh: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                TextButton(
                  onPressed: () => _loadSampleFile(isDocx: false),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Mẫu PDF (34 trang)', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => _loadSampleFile(isDocx: true),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Mẫu DOCX (18 trang)', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusCancelled.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.statusCancelled, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.statusCancelled, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (hasFile) ...[
              const SizedBox(height: 16),
              // Document Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _fileNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên hiển thị tài liệu',
                        prefixIcon: Icon(Icons.edit_note),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // File Size Badge
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dung lượng', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  _formattedSize,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Detected Page Count
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome, size: 12, color: AppColors.secondary),
                                    SizedBox(width: 4),
                                    Text('Tự đọc số trang', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_detectedPageCount trang',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Điều chỉnh số trang:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            final current = int.tryParse(_pageCountController.text) ?? 1;
                            if (current > 1) {
                              setState(() {
                                _detectedPageCount = current - 1;
                                _pageCountController.text = (current - 1).toString();
                              });
                            }
                          },
                        ),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _pageCountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                            ),
                            onChanged: (val) {
                              final p = int.tryParse(val);
                              if (p != null && p > 0) {
                                setState(() => _detectedPageCount = p);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            final current = int.tryParse(_pageCountController.text) ?? 1;
                            setState(() {
                              _detectedPageCount = current + 1;
                              _pageCountController.text = (current + 1).toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            // Upload Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _isUploading ? 'Đang tải lên hệ thống...' : 'Xác Nhận Tải Lên',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: (!hasFile || _isUploading || _isAnalyzing) ? null : _handleUpload,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
