// lib/utils/qr_pdf_exporter.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// ĐÃ XÓA: Dòng import 'package:qr_flutter/qr_flutter.dart'; gây cảnh báo Unused import

Future<void> exportQRtoPDF({
  required String productName,
  required double price,
  required String qrData,
}) async {
  final doc = pw.Document();

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    build: (context) => pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(productName,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 16),
        pw.Text(
          '${price.toStringAsFixed(0)}đ',
          style: pw.TextStyle(fontSize: 18, color: PdfColors.green800),
        ),
        pw.SizedBox(height: 24),
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: qrData,
          width: 200, height: 200,
        ),
        pw.SizedBox(height: 16),
        pw.Text('Quét mã QR để xem thông tin sản phẩm',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
      ],
    ),
  ));

  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}