import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uniprint_mobile/models/price_config_model.dart';
import 'package:uniprint_mobile/providers/price_config_provider.dart';
import 'package:uniprint_mobile/views/admin/price_config_screen.dart';

const seed = PriceConfigModel(
  id: 'cfg-1',
  pricePerBWPage: 350,
  pricePerColorPage: 1500,
  doubleSidedDiscountPercent: 10,
  bindingPrice: 5000,
  staplePrice: 1000,
);

class FakePriceConfigProvider extends PriceConfigProvider {
  final List<PriceConfigModel> submitted = [];
  PriceConfigModel active = seed;

  @override
  Future<PriceConfigModel> fetchActive() async => active;

  @override
  Future<List<PriceConfigModel>> fetchHistory() async => [active];

  @override
  Future<({PriceConfigModel config, String message})> submitUpdate(
    PriceConfigModel config,
  ) async {
    submitted.add(config);
    active = config;
    return (config: config, message: 'Đã cập nhật bảng giá.');
  }
}

void main() {
  test('Estimate matches backend price formula', () {
    expect(seed.estimate(pageCount: 10), 3500);
    expect(seed.estimate(pageCount: 10, isDoubleSided: true), 3150);
    expect(
      seed.estimate(pageCount: 10, copies: 2, isColor: true, hasBinding: true),
      40000,
    );
    expect(seed.estimate(pageCount: 10, hasStaple: true), 4500);
  });

  test('Validation mirrors backend rules', () {
    expect(seed.validate(), isEmpty);
    PriceConfigModel w({
      double bw = 350,
      double color = 1500,
      double discount = 10,
      double binding = 5000,
      double staple = 1000,
    }) => PriceConfigModel(
      pricePerBWPage: bw,
      pricePerColorPage: color,
      doubleSidedDiscountPercent: discount,
      bindingPrice: binding,
      staplePrice: staple,
    );
    expect(w(bw: 0).validate(), isNotEmpty);
    expect(w(color: 300).validate(), isNotEmpty);
    expect(w(discount: 100).validate(), isNotEmpty);
    expect(w(binding: -1).validate(), isNotEmpty);
    expect(w(staple: 2000000).validate(), isNotEmpty);
  });

  test('Provider refuses unchanged or invalid config without calling API', () async {
    final provider = FakePriceConfigProvider();
    await provider.load();
    expect(await provider.save(seed), isNull);
    expect(provider.errorMessage, contains('không có thay đổi'));
    expect(
      await provider.save(
        const PriceConfigModel(
          pricePerBWPage: 0,
          pricePerColorPage: 1500,
          doubleSidedDiscountPercent: 10,
          bindingPrice: 5000,
          staplePrice: 1000,
        ),
      ),
      isNull,
    );
    expect(provider.submitted, isEmpty);
  });

  testWidgets('Admin edits price and saves after confirmation', (tester) async {
    final provider = FakePriceConfigProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<PriceConfigProvider>.value(
        value: provider,
        child: const MaterialApp(home: PriceConfigScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final bwField = find.widgetWithText(TextFormField, 'Giá in đen trắng / trang');
    expect(bwField, findsOneWidget);
    expect(find.widgetWithText(TextFormField, '350'), findsOneWidget);

    await tester.enterText(bwField, '400');
    await tester.pump();
    await tester.tap(find.text('Lưu bảng giá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(provider.submitted.single.pricePerBWPage, 400);
    expect(find.text('Đã cập nhật bảng giá.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
