class ApiEndpoints {
  // Use http://10.0.2.2:5045 for Android Emulator
  // Use http://localhost:5045 for Windows Desktop
  // Use your LAN IP (e.g., http://192.168.1.x:5045) for physical Android devices
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5045/api',
  );

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String profile = '$baseUrl/auth/me';

  // Document endpoints
  static const String documents = '$baseUrl/documents';
  static const String uploadDocument = '$baseUrl/documents/upload';
  static const String myDocuments = '$baseUrl/documents/my-documents';

  // Print Order endpoints
  static const String printOrders = '$baseUrl/printorders';
  static const String calculatePrice = '$baseUrl/printorders/calculate-price';
  static const String myOrders = '$baseUrl/printorders/my-orders';
  static const String staffQueue = '$baseUrl/printorders/queue';
  static const String scanPickupQr = '$baseUrl/printorders/scan-pickup-qr';

  static String orderById(String id) => '$baseUrl/printorders/$id';
  static String updateOrderStatus(String id) =>
      '$baseUrl/printorders/$id/status';
  static String assignShelf(String id) =>
      '$baseUrl/printorders/$id/assign-shelf';
  static String cancelOrder(String id) => '$baseUrl/printorders/$id/cancel';
}
