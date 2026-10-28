/// Backend lưu thời gian theo UTC nhưng EF Core có thể trả về chuỗi không kèm "Z".
/// Hàm này luôn hiểu chuỗi không có múi giờ là UTC rồi đổi sang giờ máy.
DateTime? parseServerDate(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
  return DateTime.tryParse(hasZone ? raw : '${raw}Z')?.toLocal();
}
