class ShelfModel {
  final String id;
  final String shelfCode;
  final String location;
  final int maxCapacity;
  final int currentCount;
  final DateTime createdAt;

  ShelfModel({
    required this.id,
    required this.shelfCode,
    required this.location,
    required this.maxCapacity,
    required this.currentCount,
    required this.createdAt,
  });

  bool get isAvailable => currentCount < maxCapacity;
  double get occupancyRatio =>
      maxCapacity > 0 ? (currentCount / maxCapacity).clamp(0.0, 1.0) : 0.0;
  int get availableSlots => (maxCapacity - currentCount).clamp(0, maxCapacity);

  factory ShelfModel.fromJson(Map<String, dynamic> json) {
    return ShelfModel(
      id: json['id']?.toString() ?? '',
      shelfCode: json['shelfCode']?.toString() ?? '',
      location: json['location']?.toString() ?? 'Main Library Floor 1',
      maxCapacity: (json['maxCapacity'] as num?)?.toInt() ?? 20,
      currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shelfCode': shelfCode,
      'location': location,
      'maxCapacity': maxCapacity,
      'currentCount': currentCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ShelfInventoryOrder {
  final String orderId;
  final String orderCode;
  final String studentName;
  final String documentName;
  final int numberOfCopies;
  final bool isColor;
  final bool isDoubleSided;
  final double totalPrice;
  final String status;
  final bool isPaid;
  final DateTime createdAt;

  ShelfInventoryOrder({
    required this.orderId,
    required this.orderCode,
    required this.studentName,
    required this.documentName,
    required this.numberOfCopies,
    required this.isColor,
    required this.isDoubleSided,
    required this.totalPrice,
    required this.status,
    required this.isPaid,
    required this.createdAt,
  });

  factory ShelfInventoryOrder.fromJson(Map<String, dynamic> json) {
    return ShelfInventoryOrder(
      orderId: json['orderId']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'N/A',
      documentName: json['documentName']?.toString() ?? 'N/A',
      numberOfCopies: (json['numberOfCopies'] as num?)?.toInt() ?? 1,
      isColor: json['isColor'] == true,
      isDoubleSided: json['isDoubleSided'] == true,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? '',
      isPaid: json['isPaid'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ShelfInventoryItem extends ShelfModel {
  final List<ShelfInventoryOrder> storedOrders;

  ShelfInventoryItem({
    required super.id,
    required super.shelfCode,
    required super.location,
    required super.maxCapacity,
    required super.currentCount,
    required super.createdAt,
    required this.storedOrders,
  });

  factory ShelfInventoryItem.fromJson(Map<String, dynamic> json) {
    var rawOrders = json['storedOrders'] as List? ?? [];
    var orders = rawOrders
        .map((e) => ShelfInventoryOrder.fromJson(e as Map<String, dynamic>))
        .toList();

    return ShelfInventoryItem(
      id: json['id']?.toString() ?? '',
      shelfCode: json['shelfCode']?.toString() ?? '',
      location: json['location']?.toString() ?? 'Main Library Floor 1',
      maxCapacity: (json['maxCapacity'] as num?)?.toInt() ?? 20,
      currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      storedOrders: orders,
    );
  }
}

class ShelfInventorySummary {
  final int totalShelves;
  final int totalCapacity;
  final int totalStoredOrders;
  final int availableShelvesCount;
  final int fullShelvesCount;
  final double overallOccupancyRate;

  ShelfInventorySummary({
    required this.totalShelves,
    required this.totalCapacity,
    required this.totalStoredOrders,
    required this.availableShelvesCount,
    required this.fullShelvesCount,
    required this.overallOccupancyRate,
  });

  factory ShelfInventorySummary.fromJson(Map<String, dynamic> json) {
    return ShelfInventorySummary(
      totalShelves: (json['totalShelves'] as num?)?.toInt() ?? 0,
      totalCapacity: (json['totalCapacity'] as num?)?.toInt() ?? 0,
      totalStoredOrders: (json['totalStoredOrders'] as num?)?.toInt() ?? 0,
      availableShelvesCount:
          (json['availableShelvesCount'] as num?)?.toInt() ?? 0,
      fullShelvesCount: (json['fullShelvesCount'] as num?)?.toInt() ?? 0,
      overallOccupancyRate:
          (json['overallOccupancyRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ShelfInventoryResponse {
  final ShelfInventorySummary summary;
  final List<ShelfInventoryItem> shelves;

  ShelfInventoryResponse({
    required this.summary,
    required this.shelves,
  });

  factory ShelfInventoryResponse.fromJson(Map<String, dynamic> json) {
    var rawShelves = json['shelves'] as List? ?? [];
    return ShelfInventoryResponse(
      summary: ShelfInventorySummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? {},
      ),
      shelves: rawShelves
          .map((e) => ShelfInventoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
