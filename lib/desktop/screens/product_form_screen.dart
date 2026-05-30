import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/models/product.dart';
import '../../shared/image_picker_widget.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '0');
  bool   _isOutOfStock  = false;
  bool   _isUnavailable = false;
  String? _imageUrl;
  bool   _saving = false;

  final _numFmt = NumberFormat('#,###', 'vi_VN');

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text     = p.name;
      _descCtrl.text     = p.description ?? '';
      _priceCtrl.text    = _numFmt.format(p.price.toInt());
      _quantityCtrl.text = p.quantity.toString();
      _isOutOfStock      = p.isOutOfStock;
      _isUnavailable     = p.isUnavailable;
      _imageUrl          = p.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose();
    _priceCtrl.dispose(); _quantityCtrl.dispose();
    super.dispose();
  }

  double _parsePrice() {
    final raw = _priceCtrl.text.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final price = _parsePrice();
    if (price <= 0) {
      _snack('Vui lòng nhập giá hợp lệ', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final data = {
        'name':            _nameCtrl.text.trim(),
        'description':     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'price':           price,
        'quantity':        int.tryParse(_quantityCtrl.text) ?? 0,
        'image_url':       _imageUrl,
        'is_out_of_stock': _isOutOfStock,
        'is_unavailable':  _isUnavailable,
      };
      if (isEditing) {
        await apiService.updateProduct(widget.product!.id, data);
      } else {
        await apiService.createProduct(data);
      }
      if (mounted) {
        _snack(isEditing ? '✅ Đã cập nhật sản phẩm' : '✅ Đã thêm sản phẩm mới');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        String msg = 'Không thể lưu sản phẩm';
        if (e.toString().contains('connection')) {
          msg = 'Không kết nối được server. Kiểm tra backend.';
        }
        _snack('❌ $msg', isError: true);
      }
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Text(isEditing ? 'Cập Nhật Sản Phẩm' : 'Thêm Sản Phẩm Mới',
          style: const TextStyle(fontWeight: FontWeight.bold,
              color: Color(0xFF1A1D2E))),
        leading: BackButton(color: const Color(0xFF1A1D2E)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 720 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên + Mô tả
                  _card(children: [
                    _lbl('Tên sản phẩm *'), const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl, maxLength: 100,
                      decoration: _deco(hint: 'Nhập tên sản phẩm',
                          helper: 'Không quá 100 ký tự'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Vui lòng nhập tên sản phẩm' : null,
                    ),
                    const SizedBox(height: 16),
                    _lbl('Mô tả sản phẩm'), const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl, maxLength: 5000, maxLines: 3,
                      decoration: _deco(hint: 'Nhập mô tả (tuỳ chọn)',
                          helper: 'Không quá 5000 ký tự'),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Giá + số lượng
                  _card(children: [
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _lbl('Giá niêm yết *'), const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _PriceFmt(),
                            ],
                            decoration: _deco(hint: 'Nhập giá',
                              suffix: const Text('đ', style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2DBD8F)))),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập giá';
                              if (_parsePrice() <= 0) return 'Giá phải lớn hơn 0';
                              return null;
                            },
                          ),
                        ],
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _lbl('Số lượng bán ra'), const SizedBox(height: 8),
                          TextFormField(
                            controller: _quantityCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _deco(hint: 'Mặc định: 0'),
                          ),
                        ],
                      )),
                    ]),
                  ]),
                  const SizedBox(height: 16),

                  // FIX SLIDE 2: Dùng ImagePickerWidget mới – click thực sự hoạt động
                  _card(children: [
                    _lbl('Ảnh chụp sản phẩm *'), const SizedBox(height: 12),
                    ImagePickerWidget(
                      initialUrl: _imageUrl,
                      onImageSelected: (url) =>
                          setState(() => _imageUrl = url),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Trạng thái (chỉ khi edit)
                  if (isEditing) _card(children: [
                    _lbl('Trạng thái'), const SizedBox(height: 8),
                    _Toggle(
                      title: 'Đã hết hàng', value: _isOutOfStock,
                      onChange: (v) => setState(() => _isOutOfStock = v)),
                    const Divider(height: 20),
                    _Toggle(
                      title: 'Không khả dụng',
                      subtitle: 'Sản phẩm sẽ không được bán và không thể xem',
                      value: _isUnavailable,
                      onChange: (v) => setState(() => _isUnavailable = v)),
                  ]),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F7FFA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Text(isEditing ? 'Cập nhật' : 'Lưu sản phẩm',
                                style: const TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Hủy', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _lbl(String t) => Text(t,
    style: const TextStyle(fontWeight: FontWeight.w600,
        fontSize: 13, color: Color(0xFF1A1D2E)));

  InputDecoration _deco({String? hint, String? helper, Widget? suffix}) =>
    InputDecoration(
      hintText: hint, helperText: helper,
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 40),
      filled: true, fillColor: const Color(0xFFF8F9FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E4F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E4F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F7FFA), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
}

class _Toggle extends StatelessWidget {
  final String title; final String? subtitle;
  final bool value; final ValueChanged<bool> onChange;
  const _Toggle({required this.title, this.subtitle,
      required this.value, required this.onChange});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(subtitle!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    ])),
    Switch(value: value, onChanged: onChange,
        activeColor: const Color(0xFF4F7FFA)),
  ]);
}

class _PriceFmt extends TextInputFormatter {
  final _fmt = NumberFormat('#,###', 'vi_VN');
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue v) {
    if (v.text.isEmpty) return v;
    final digits = v.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return v.copyWith(text: '');
    final num = int.tryParse(digits) ?? 0;
    final formatted = _fmt.format(num);
    return v.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length));
  }
}