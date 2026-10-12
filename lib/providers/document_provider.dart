import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentProvider extends ChangeNotifier {
  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDocuments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documents = await DocumentService.getMyDocuments();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DocumentModel?> uploadDocument({
    required String fileName,
    required String fileExtension,
    required int fileSizeBytes,
    required int pageCount,
    String? filePath,
    List<int>? fileBytes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await DocumentService.uploadDocument(
        fileName: fileName,
        fileExtension: fileExtension,
        fileSizeBytes: fileSizeBytes,
        pageCount: pageCount,
        filePath: filePath,
        fileBytes: fileBytes,
      );
      _documents.insert(0, doc);
      _isLoading = false;
      notifyListeners();
      return doc;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<DocumentModel?> uploadMeta({
    required String fileName,
    required String fileExtension,
    required int fileSizeBytes,
    required int pageCount,
  }) async {
    return uploadDocument(
      fileName: fileName,
      fileExtension: fileExtension,
      fileSizeBytes: fileSizeBytes,
      pageCount: pageCount,
    );
  }

  Future<bool> deleteDocument(String documentId, {String? currentUserId}) async {
    // Ownership check before deletion
    final docIndex = _documents.indexWhere((d) => d.id == documentId);
    if (docIndex != -1) {
      final doc = _documents[docIndex];
      if (!doc.isOwner(currentUserId)) {
        _errorMessage = 'Bạn không có quyền xóa tài liệu này. Chỉ chủ sở hữu mới được xóa.';
        notifyListeners();
        return false;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await DocumentService.deleteDocument(documentId);
      _documents.removeWhere((d) => d.id == documentId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
