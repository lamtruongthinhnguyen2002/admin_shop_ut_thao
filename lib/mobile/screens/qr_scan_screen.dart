import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api_service.dart';
import 'order_form_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét Mã QR Sản Phẩm')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (scanned) return;
              final barcode = capture.barcodes.first;
              final productId = barcode.rawValue;
              if (productId == null) return;

              setState(() => scanned = true);

              // Lấy thông tin sản phẩm từ QR
              try {
                final products = await apiService.getProducts();
                final product = products.firstWhere((p) => p['id'] == productId);

                if (mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => OrderFormScreen(product: product),
                  ));
                }
              } catch (e) {
                setState(() => scanned = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không tìm thấy sản phẩm')));
              }
            },
          ),
          // Khung ngắm QR
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0, right: 0,
            child: Center(
              child: Text(
                'Đưa mã QR sản phẩm vào khung',
                style: TextStyle(color: Colors.white,
                    backgroundColor: Colors.black54, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}