import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/models/product.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _quantityCtrl= TextEditingController(text: '0');

  bool   _isOutOfStock  = false;
  bool   _isUnavailable = false;
  String? _imageUrl;
  bool   _saving        = false;

  // FIX 3: Formatter số tiền chuẩn VN
  final _numFmt = NumberFormat('#,###', 'vi_VN');

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text     = p.name;
      _descCtrl.text     = p.description ?? '';
      // FIX: Hiển thị giá đã format sẵn
      _priceCtrl.text    = _numFmt.format(p.price.toInt());
      _quantityCtrl.text = p.quantity.toString();
      _isOutOfStock      = p.isOutOfStock;
      _isUnavailable     = p.isUnavailable;
      _imageUrl          = p.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  // Parse giá từ text đã format "200.000" → 200000.0
  double _parsePrice() {
    final raw = _priceCtrl.text.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final price = _parsePrice();
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập giá hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final data = {
        'name':            _nameCtrl.text.trim(),
        'description':     _descCtrl.text.trim().isEmpty
                             ? null : _descCtrl.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? '✅ Đã cập nhật sản phẩm'
                : '✅ Đã thêm sản phẩm mới'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // trả true để page cha biết cần refresh
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        // FIX: Không hiện raw exception
        String msg = 'Không thể lưu sản phẩm';
        if (e.toString().contains('connection')) {
          msg = 'Không kết nối được server. Kiểm tra backend.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditing ? 'Cập Nhật Sản Phẩm' : 'Thêm Sản Phẩm Mới',
          style: const TextStyle(fontWeight: FontWeight.bold,
              color: Color(0xFF1A1D2E)),
        ),
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
                  _card(children: [
                    _label('Tên sản phẩm *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      maxLength: 100,
                      decoration: _inputDeco(
                          hint: 'Nhập tên sản phẩm',
                          helper: 'Không quá 100 ký tự'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Vui lòng nhập tên sản phẩm' : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Mô tả sản phẩm'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLength: 5000,
                      maxLines: 4,
                      decoration: _inputDeco(
                          hint: 'Nhập mô tả (tuỳ chọn)',
                          helper: 'Không quá 5000 ký tự'),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _card(children: [
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Giá niêm yết *'),
                          const SizedBox(height: 8),
                          // FIX 3: Format số tiền khi nhập
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _PriceInputFormatter(),
                            ],
                            decoration: _inputDeco(
                              hint: 'Nhập giá',
                              suffix: const Text('đ', style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2DBD8F))),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Vui lòng nhập giá';
                              }
                              if (_parsePrice() <= 0) {
                                return 'Giá phải lớn hơn 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Số lượng bán ra'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _quantityCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDeco(hint: 'Mặc định: 0'),
                          ),
                        ],
                      )),
                    ]),
                  ]),
                  const SizedBox(height: 16),

                  // Ảnh
                  _card(children: [
                    _label('Ảnh chụp sản phẩm *'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {/* image picker */},
                      child: Container(
                        height: 180, width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          border: Border.all(
                              color: const Color(0xFFE0E4F0),
                              style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(_imageUrl!, fit: BoxFit.cover))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F7FFA).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Text('📷', style: TextStyle(fontSize: 24))),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Nhấn để chọn ảnh',
                                    style: TextStyle(fontWeight: FontWeight.w500,
                                        color: Color(0xFF4F7FFA))),
                                  const SizedBox(height: 4),
                                  Text('Dung lượng tối đa: 2MB',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Trạng thái (chỉ enable khi đang edit)
                  if (isEditing) _card(children: [
                    _label('Trạng thái'),
                    const SizedBox(height: 8),
                    _ToggleRow(
                      title: 'Đã hết hàng',
                      value: _isOutOfStock,
                      onChanged: (v) => setState(() => _isOutOfStock = v),
                    ),
                    const Divider(height: 20),
                    _ToggleRow(
                      title: 'Không khả dụng',
                      subtitle: 'Sản phẩm sẽ không được bán và không thể xem',
                      value: _isUnavailable,
                      onChanged: (v) => setState(() => _isUnavailable = v),
                    ),
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
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Text(isEditing ? 'Cập nhật' : 'Lưu sản phẩm',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
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
                        child: const Text('Hủy',
                            style: TextStyle(fontSize: 15)),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontWeight: FontWeight.w600,
        fontSize: 13, color: Color(0xFF1A1D2E)));

  InputDecoration _inputDeco({String? hint, String? helper, Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      helperText: helper,
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 40),
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E4F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E4F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F7FFA), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red)),
    );
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title, this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(
                color: Colors.grey[500], fontSize: 12)),
          ],
        ],
      )),
      Switch(
        value: value, onChanged: onChanged,
        activeColor: const Color(0xFF4F7FFA),
      ),
    ]);
  }
}

/// FIX 3: Formatter để format "200000" → "200.000" khi nhập
class _PriceInputFormatter extends TextInputFormatter {
  final _fmt = NumberFormat('#,###', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    if (value.text.isEmpty) return value;
    final digits = value.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return value.copyWith(text: '');
    final num = int.tryParse(digits) ?? 0;
    final formatted = _fmt.format(num);
    return value.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}