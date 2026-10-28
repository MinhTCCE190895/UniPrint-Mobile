import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/price_config_model.dart';
import '../../providers/price_config_provider.dart';

/// Task 20: Admin cập nhật bảng giá in ấn (giá trang màu, đen trắng, chiết khấu 2 mặt, gáy/ghim).
class PriceConfigScreen extends StatefulWidget {
  const PriceConfigScreen({super.key});

  @override
  State<PriceConfigScreen> createState() => _PriceConfigScreenState();
}

class _PriceConfigScreenState extends State<PriceConfigScreen> {
  static final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  static final _dateFormat = DateFormat('HH:mm dd/MM/yyyy');

  final _formKey = GlobalKey<FormState>();
  final _bw = TextEditingController();
  final _color = TextEditingController();
  final _discount = TextEditingController();
  final _binding = TextEditingController();
  final _staple = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [_bw, _color, _discount, _binding, _staple]) {
      c.addListener(() => setState(() {}));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final c in [_bw, _color, _discount, _binding, _staple]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final provider = context.read<PriceConfigProvider>();
    await provider.load();
    if (mounted && provider.current != null) _fill(provider.current!);
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _fill(PriceConfigModel c) {
    _bw.text = _fmt(c.pricePerBWPage);
    _color.text = _fmt(c.pricePerColorPage);
    _discount.text = _fmt(c.doubleSidedDiscountPercent);
    _binding.text = _fmt(c.bindingPrice);
    _staple.text = _fmt(c.staplePrice);
  }

  static double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  /// Giá trị đang nhập trên form (null nếu có ô chưa phải số).
  PriceConfigModel? get _draft {
    final values = [
      _bw,
      _color,
      _discount,
      _binding,
      _staple,
    ].map((c) => _parse(c.text)).toList();
    if (values.any((v) => v == null)) return null;
    return PriceConfigModel(
      pricePerBWPage: values[0]!,
      pricePerColorPage: values[1]!,
      doubleSidedDiscountPercent: values[2]!,
      bindingPrice: values[3]!,
      staplePrice: values[4]!,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = _draft;
    if (draft == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận cập nhật bảng giá'),
        content: const Text(
          'Giá mới áp dụng cho các đơn tạo sau khi lưu. Đơn đã tạo giữ nguyên giá đã chốt (BR02).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final provider = context.read<PriceConfigProvider>();
    final message = await provider.save(draft);
    if (!mounted) return;
    if (message != null && provider.current != null) _fill(provider.current!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? provider.errorMessage ?? 'Không thể cập nhật bảng giá.'),
        backgroundColor: message != null
            ? AppColors.statusCompleted
            : AppColors.statusCancelled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriceConfigProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cấu Hình Bảng Giá'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading && provider.current == null
          ? const Center(child: CircularProgressIndicator())
          : provider.current == null
          ? _buildError(provider.errorMessage)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildForm(provider),
                  const SizedBox(height: 16),
                  _buildPreview(),
                  const SizedBox(height: 16),
                  _buildHistory(provider.history),
                ],
              ),
            ),
    );
  }

  Widget _buildError(String? error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error ?? 'Không tải được bảng giá.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.statusCancelled),
          ),
          TextButton(onPressed: _load, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String suffix,
    String? Function(double value) rule,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (text) {
        final value = _parse(text ?? '');
        if (value == null) return 'Vui lòng nhập số hợp lệ';
        if (value > PriceConfigModel.maxPrice) return 'Tối đa 1.000.000';
        return rule(value);
      },
    );
  }

  Widget _buildForm(PriceConfigProvider provider) {
    final colorBelowBw = () {
      final bw = _parse(_bw.text);
      final color = _parse(_color.text);
      return bw != null && color != null && bw > 0 && color < bw;
    }();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bảng giá đang áp dụng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              _numberField(
                _bw,
                'Giá in đen trắng / trang',
                'đ',
                (v) => v <= 0 ? 'Phải lớn hơn 0' : null,
              ),
              const SizedBox(height: 12),
              _numberField(
                _color,
                'Giá in màu / trang',
                'đ',
                (v) => v <= 0
                    ? 'Phải lớn hơn 0'
                    : colorBelowBw
                    ? 'Không được thấp hơn giá đen trắng'
                    : null,
              ),
              const SizedBox(height: 12),
              _numberField(
                _discount,
                'Chiết khấu in 2 mặt',
                '%',
                (v) => v < 0 || v >= 100 ? 'Từ 0 đến dưới 100' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      _binding,
                      'Phí đóng gáy / bản',
                      'đ',
                      (v) => v < 0 ? 'Không được âm' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      _staple,
                      'Phí bấm ghim / bản',
                      'đ',
                      (v) => v < 0 ? 'Không được âm' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                ),
                icon: provider.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu bảng giá'),
                onPressed: provider.isSaving ? null : _save,
              ),
              const SizedBox(height: 8),
              const Text(
                'Đơn đã tạo giữ nguyên giá đã chốt (BR02).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final draft = _draft;
    Widget row(String label, double? value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(
            value == null ? '—' : _currency.format(value),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return Card(
      color: AppColors.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xem trước: tài liệu 10 trang, 1 bản',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            row('Đen trắng, 1 mặt', draft?.estimate(pageCount: 10)),
            row(
              'Đen trắng, 2 mặt',
              draft?.estimate(pageCount: 10, isDoubleSided: true),
            ),
            row('Màu, 1 mặt', draft?.estimate(pageCount: 10, isColor: true)),
            row(
              'Màu, 2 mặt + đóng gáy',
              draft?.estimate(
                pageCount: 10,
                isColor: true,
                isDoubleSided: true,
                hasBinding: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(List<PriceConfigModel> history) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử bảng giá',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Text(
                'Chưa có lịch sử.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            for (final h in history)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  h.isActive ? Icons.check_circle : Icons.history,
                  color: h.isActive
                      ? AppColors.statusCompleted
                      : AppColors.textLight,
                ),
                title: Text(
                  'ĐT ${_currency.format(h.pricePerBWPage)} • Màu ${_currency.format(h.pricePerColorPage)} • -${_fmt(h.doubleSidedDiscountPercent)}%',
                ),
                subtitle: Text(
                  'Gáy ${_currency.format(h.bindingPrice)} • Ghim ${_currency.format(h.staplePrice)}'
                  '${h.createdAt != null ? ' • ${_dateFormat.format(h.createdAt!)}' : ''}',
                ),
                trailing: h.isActive
                    ? const Text(
                        'Đang áp dụng',
                        style: TextStyle(
                          color: AppColors.statusCompleted,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
