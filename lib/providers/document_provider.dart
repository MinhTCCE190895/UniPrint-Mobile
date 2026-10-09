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

  Future<DocumentModel?> uploadMeta({
    required String fileName,
    required String fileExtension,
    required int fileSizeBytes,
    required int pageCount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await DocumentService.uploadDocumentMeta(
        fileName: fileName,
        fileExtension: fileExtension,
        fileSizeBytes: fileSizeBytes,
        pageCount: pageCount,
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
}
