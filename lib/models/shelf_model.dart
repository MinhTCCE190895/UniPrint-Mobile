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
