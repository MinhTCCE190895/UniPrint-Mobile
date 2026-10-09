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
    return DocumentModel.fromJson(data);
  }

  static Future<void> deleteDocument(String id) async {
    await ApiClient.delete('${ApiEndpoints.documents}/$id', withAuth: true);
  }
}
