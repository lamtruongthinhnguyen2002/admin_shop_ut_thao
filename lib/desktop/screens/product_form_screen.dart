import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_service.dart';
import '../../core/models/product.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = thêm mới, có giá trị = cập nhật

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get isEditing => widget.product != null;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _quantityCtrl;
  bool _isOutOfStock = false;
  bool _isUnavailable = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toStringAsFixed(0) ?? '');
    _quantityCtrl = TextEditingController(text: p?.quantity.toString() ?? '0');
    _isOutOfStock = p?.isOutOfStock ?? false;
    _isUnavailable = p?.isUnavailable ?? false;
    _imageUrl = p?.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Cập Nhật Sản Phẩm' : 'Thêm Sản Phẩm Mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên sản phẩm (*)
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên sản phẩm (*)',
                  helperText: 'Không quá 100 ký tự',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mô tả sản phẩm',
                  helperText: 'Không quá 5000 ký tự',
                  border: OutlineInputBorder(),
                ),
                maxLength: 5000,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Giá niêm yết (*) - Đơn vị đồng
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Giá niêm yết (*)',
                  suffixText: 'đ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập giá' : null,
              ),
              const SizedBox(height: 16),

              // Số lượng bán ra (*) - Mặc định 0
              TextFormField(
                controller: _quantityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số lượng bán ra (*)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Ảnh chụp sản phẩm (*)
              const Text('Ảnh chụp sản phẩm (*)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageUrl != null
                    ? Image.network(_imageUrl!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                          Text('Nhấn để chọn ảnh',
                              style: TextStyle(color: Colors.grey)),
                          Text('Độ phân giải tối đa: 2MB',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 16),

              // Checkboxes (bị mờ khi thêm mới, sáng lên khi cập nhật)
              CheckboxListTile(
                title: const Text('Đã hết hàng'),
                value: _isOutOfStock,
                onChanged: isEditing ? (v) => setState(() => _isOutOfStock = v!) : null,
              ),
              CheckboxListTile(
                title: const Text('Không khả dụng'),
                subtitle: const Text('Sản phẩm sẽ không được bán và không thể xem'),
                value: _isUnavailable,
                onChanged: isEditing ? (v) => setState(() => _isUnavailable = v!) : null,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Lưu', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Hủy', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      // Upload ảnh lên server, lấy URL
      // Tạm thời giả lập
      setState(() => _imageUrl = file.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameCtrl.text,
      'description': _descCtrl.text.isEmpty ? null : _descCtrl.text,
      'price': double.parse(_priceCtrl.text),
      'quantity': int.parse(_quantityCtrl.text),
      'image_url': _imageUrl,
      'is_out_of_stock': _isOutOfStock,
      'is_unavailable': _isUnavailable,
    };

    try {
      if (isEditing) {
        await apiService.updateProduct(widget.product!.id, data);
      } else {
        await apiService.createProduct(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')));
    }
  }
}