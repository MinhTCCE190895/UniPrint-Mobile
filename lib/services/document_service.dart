import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/document_model.dart';

class DocumentService {
  static Future<List<DocumentModel>> getMyDocuments() async {
    final response = await ApiClient.get(ApiEndpoints.myDocuments, withAuth: true);
    final data = (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;

    if (data is List) {
      return data.map((item) => DocumentModel.fromJson(item)).toList();
    }
    return [];
  }

  static Future<DocumentModel> uploadDocument({
    required String fileName,
    required String fileExtension,
    required int fileSizeBytes,
    required int pageCount,
    String? filePath,
    List<int>? fileBytes,
  }) async {
    // If we have actual file content, try multipart upload first
    if (filePath != null || fileBytes != null) {
      try {
        final response = await ApiClient.uploadMultipart(
          ApiEndpoints.uploadDocument,
          fileField: 'file',
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          fields: {
            'fileName': fileName,
            'fileExtension': fileExtension,
            'fileSizeBytes': fileSizeBytes.toString(),
            'pageCount': pageCount.toString(),
            'tempStoragePath': 'mobile_upload/$fileName',
          },
          withAuth: true,
        );

        final data = (response is Map<String, dynamic> && response.containsKey('data'))
            ? response['data']
            : response;
        if (data is Map<String, dynamic>) {
          return DocumentModel.fromJson(data);
        }
      } catch (e) {
        // If multipart endpoint failed due to content-type or structure, fallback to JSON metadata endpoint
      }
    }

    return uploadDocumentMeta(
      fileName: fileName,
      fileExtension: fileExtension,
      fileSizeBytes: fileSizeBytes,
      pageCount: pageCount,
    );
  }

  static Future<DocumentModel> uploadDocumentMeta({
    required String fileName,
    required String fileExtension,
    required int fileSizeBytes,
    required int pageCount,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.uploadDocument,
      body: {
        'fileName': fileName,
        'fileExtension': fileExtension,
        'fileSizeBytes': fileSizeBytes,
        'pageCount': pageCount,
        'tempStoragePath': 'mobile_upload/$fileName',
      },
      withAuth: true,
    );

    final data = (response is Map<String, dynamic> && response.containsKey('data'))
        ? response['data']
        : response;
    return DocumentModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteDocument(String id) async {
    await ApiClient.delete('${ApiEndpoints.documents}/$id', withAuth: true);
  }
}
