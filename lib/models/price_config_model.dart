import '../core/utils/server_date.dart';

/// Task 20: Bảng giá in ấn hệ thống (khớp PriceConfigDto của backend).
class PriceConfigModel {
  static const double maxPrice = 1000000;

  final String id;
  final double pricePerBWPage;
  final double pricePerColorPage;
  final double doubleSidedDiscountPercent;
  final double bindingPrice;
  final double staplePrice;
  final bool isActive;
  final DateTime? createdAt;

  const PriceConfigModel({
    this.id = '',
    required this.pricePerBWPage,
    required this.pricePerColorPage,
    required this.doubleSidedDiscountPercent,
    required this.bindingPrice,
    required this.staplePrice,
    this.isActive = true,
    this.createdAt,
  });

  factory PriceConfigModel.fromJson(Map<String, dynamic> json) {
    double n(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return PriceConfigModel(
      id: json['id']?.toString() ?? '',
      pricePerBWPage: n('pricePerBWPage'),
      pricePerColorPage: n('pricePerColorPage'),
      doubleSidedDiscountPercent: n('doubleSidedDiscountPercent'),
      bindingPrice: n('bindingPrice'),
      staplePrice: n('staplePrice'),
      isActive: json['isActive'] == true,
      createdAt: parseServerDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
    'pricePerBWPage': pricePerBWPage,
    'pricePerColorPage': pricePerColorPage,
    'doubleSidedDiscountPercent': doubleSidedDiscountPercent,
    'bindingPrice': bindingPrice,
    'staplePrice': staplePrice,
  };

  /// Cùng công thức với PriceCalculatorService (Task 8) để xem trước giá.
  double estimate({
    required int pageCount,
    int copies = 1,
    bool isColor = false,
    bool isDoubleSided = false,
    bool hasBinding = false,
    bool hasStaple = false,
  }) {
    var unit = isColor ? pricePerColorPage : pricePerBWPage;
    if (isDoubleSided && doubleSidedDiscountPercent > 0) {
      unit -= unit * doubleSidedDiscountPercent / 100;
    }
    var total = unit * pageCount * copies;
    if (hasBinding) total += bindingPrice * copies;
    if (hasStaple) total += staplePrice * copies;
    return total;
  }

  /// Kiểm tra hợp lệ giống backend để báo lỗi ngay trên form.
  List<String> validate() {
    final errors = <String>[];
    if (pricePerBWPage <= 0) {
      errors.add('Giá in đen trắng mỗi trang phải lớn hơn 0.');
    }
    if (pricePerColorPage <= 0) {
      errors.add('Giá in màu mỗi trang phải lớn hơn 0.');
    }
    if (pricePerBWPage > 0 &&
        pricePerColorPage > 0 &&
        pricePerColorPage < pricePerBWPage) {
      errors.add('Giá in màu không được thấp hơn giá in đen trắng.');
    }
    if (doubleSidedDiscountPercent < 0 || doubleSidedDiscountPercent >= 100) {
      errors.add('Chiết khấu in 2 mặt phải từ 0% đến dưới 100%.');
    }
    if (bindingPrice < 0) errors.add('Phí đóng gáy không được âm.');
    if (staplePrice < 0) errors.add('Phí bấm ghim không được âm.');
    if ([
      pricePerBWPage,
      pricePerColorPage,
      bindingPrice,
      staplePrice,
    ].any((p) => p > maxPrice)) {
      errors.add('Mỗi mức giá tối đa 1.000.000đ.');
    }
    return errors;
  }

  bool sameValuesAs(PriceConfigModel other) =>
      pricePerBWPage == other.pricePerBWPage &&
      pricePerColorPage == other.pricePerColorPage &&
      doubleSidedDiscountPercent == other.doubleSidedDiscountPercent &&
      bindingPrice == other.bindingPrice &&
      staplePrice == other.staplePrice;
}
