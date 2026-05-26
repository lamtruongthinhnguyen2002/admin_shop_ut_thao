import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api_service.dart';
import '../../core/models/product.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await apiService.getProducts();
    setState(() {
      products = data.map((e) => Product.fromJson(e)).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quản Lý Sản Phẩm',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()))
                  .then((_) => _loadProducts()),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Sản Phẩm'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Tổng cộng: ${products.length} sản phẩm',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),

          Expanded(
            child: loading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => _ProductCard(
                    product: products[i],
                    onEdit: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                        ProductFormScreen(product: products[i])))
                      .then((_) => _loadProducts()),
                    onViewQR: () => _showQRDialog(products[i]),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  void _showQRDialog(Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mã QR – ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: product.qrCode, size: 200),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _exportQRtoPDF(product),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Xuất file PDF'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> _exportQRtoPDF(Product product) async {
    // Dùng package pdf + printing để xuất file PDF chứa mã QR
    // Xem mục "Xuất PDF" bên dưới
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onViewQR;

  const _ProductCard({required this.product, required this.onEdit, required this.onViewQR});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh sản phẩm
          AspectRatio(
            aspectRatio: 16 / 9,
            child: product.imageUrl != null
              ? Image.network(product.imageUrl!, fit: BoxFit.cover)
              : Container(color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 48, color: Colors.grey)),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (product.description != null)
                  Text(product.description!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(_formatVND(product.price),
                    style: const TextStyle(color: Colors.green,
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (product.isOutOfStock)
                  const Chip(label: Text('Hết hàng'), backgroundColor: Colors.red),
                if (product.isUnavailable)
                  const Chip(label: Text('Không khả dụng'), backgroundColor: Colors.grey),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewQR,
                        icon: const Icon(Icons.qr_code, size: 16),
                        label: const Text('Xem QR'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatVND(double price) =>
    '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}đ';
}