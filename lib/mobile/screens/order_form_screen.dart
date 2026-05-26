import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class OrderFormScreen extends StatefulWidget {
  final Map<String, dynamic> product; // Dữ liệu sản phẩm từ QR

  const OrderFormScreen({super.key, required this.product});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _quantityCtrl = TextEditingController(text: '1');
  final _discountCtrl = TextEditingController(text: '0');
  final _amountPaidCtrl = TextEditingController();

  double get price => (widget.product['price'] as num).toDouble();
  int get quantity => int.tryParse(_quantityCtrl.text) ?? 1;
  double get discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get amountPaid => double.tryParse(_amountPaidCtrl.text) ?? 0;

  // Tính toán tự động
  double get amountDue => price * quantity;
  double get change => amountPaid - amountDue - discount; // Số tiền trừ lại
  double get debt => (amountPaid - amountDue) < 0 ? 0 : (amountPaid - amountDue);
  double get totalRevenue => amountPaid - discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Đơn Hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin sản phẩm từ QR
            Card(
              color: Colors.blue[50],
              child: ListTile(
                leading: widget.product['image_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(widget.product['image_url'],
                          width: 56, height: 56, fit: BoxFit.cover))
                  : const Icon(Icons.inventory, size: 40),
                title: Text(widget.product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_vnd(price),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.qr_code, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),

            // Mã đơn hàng (Tự động)
            _ReadonlyField(label: 'Mã đơn hàng', value: 'Tự động tạo'),

            // Tên đơn hàng (tự điền)
            _ReadonlyField(label: 'Tên đơn hàng', value: widget.product['name']),

            const SizedBox(height: 12),

            // Số lượng (mặc định 1)
            TextField(
              controller: _quantityCtrl,
              decoration: const InputDecoration(
                labelText: 'Số lượng', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Số tiền phải trả (tự động tính = giá × số lượng)
            _ReadonlyField(
              label: 'Số tiền phải trả',
              value: _vnd(amountDue),
              highlight: true,
            ),
            const SizedBox(height: 12),

            // Giảm giá (mặc định 0)
            TextField(
              controller: _discountCtrl,
              decoration: const InputDecoration(
                labelText: 'Giảm giá (đ)',
                border: OutlineInputBorder(),
                prefixText: '-',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Số tiền khách trả (user nhập tay)
            TextField(
              controller: _amountPaidCtrl,
              decoration: const InputDecoration(
                labelText: 'Số tiền khách trả (đ)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Số tiền trừ lại (tự động)
            _ReadonlyField(
              label: 'Số tiền trừ lại',
              value: _vnd(change),
              highlight: true,
              color: change >= 0 ? Colors.green : Colors.red,
            ),

            // Công nợ (tự động, nếu âm = 0)
            _ReadonlyField(
              label: 'Công nợ',
              value: _vnd(debt),
              highlight: true,
              color: debt > 0 ? Colors.orange : Colors.green,
            ),

            // Tổng doanh thu (tự động)
            _ReadonlyField(
              label: 'Tổng doanh thu',
              value: _vnd(totalRevenue),
              highlight: true,
              color: Colors.blue,
            ),

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit – Đồng Bộ Đơn Hàng',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    try {
      await apiService.createOrder({
        'product_id': widget.product['id'],
        'product_name': widget.product['name'],
        'quantity': quantity,
        'amount_due': amountDue,
        'discount': discount,
        'amount_paid': amountPaid,
        'debt': debt,
        'total_revenue': totalRevenue,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đơn hàng đã được đồng bộ!')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')));
    }
  }

  String _vnd(double v) =>
    '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}đ';
}

class _ReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? color;

  const _ReadonlyField({
    required this.label, required this.value,
    this.highlight = false, this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: highlight ? (color ?? Colors.blue).withOpacity(0.08) : Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
              fontSize: 16,
            )),
        ],
      ),
    );
  }
}