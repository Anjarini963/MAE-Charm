import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Used for date formatting
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';

class Coupons extends StatelessWidget {
  final String collectionId;
  final String username;
  final String category;
  final String restaurant;
  final String date;
  final String couponCode;

  const Coupons({
    Key? key,
    required this.collectionId,
    required this.username,
    required this.category,
    required this.restaurant,
    required this.date,
    required this.couponCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(date));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Your Coupon', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            QrImageView(
              data: couponCode,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 20),
            const Text('Coupon Code:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(couponCode, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const Divider(),
            const Text('Purchase Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            buildDetailRow('Name:', username),
            buildDetailRow('Category:', category),
            buildDetailRow('Merchant:', restaurant),
            buildDetailRow('Date of Purchase:', formattedDate),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.download, color: Colors.white),
          label: const Text('Download Coupon', style: TextStyle(color: Colors.white, fontSize: 16)),
          onPressed: () async {
            await _generatePdfAndDownload(
              context,
              username,
              category,
              restaurant,
              formattedDate,
              couponCode,
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.red,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _generatePdfAndDownload(
    BuildContext context,
    String username,
    String category,
    String restaurant,
    String date,
    String couponCode,
  ) async {
    final pdf = pw.Document();

    final qrImage = await _generateQrImage(couponCode);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(pw.MemoryImage(qrImage), width: 200, height: 200),
              pw.Text('Coupon Code:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(couponCode, style: pw.TextStyle(fontSize: 16)),
              pw.Divider(),
              pw.Text('Purchase Details:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _buildDetailRowPdf('Name:', username),
              _buildDetailRowPdf('Category:', category),
              _buildDetailRowPdf('Merchant:', restaurant),
              _buildDetailRowPdf('Date of Purchase:', date),
            ],
          ),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/coupon.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon downloaded to ${file.path}')),
    );
  }

  Future<Uint8List> _generateQrImage(String data) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        gapless: true,
      );
      final image = await painter.toImageData(200);
      return image!.buffer.asUint8List();
    } else {
      throw Exception('Could not generate QR code');
    }
  }

  pw.Widget _buildDetailRowPdf(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey, fontSize: 16)),
          pw.Text(value, style: const pw.TextStyle(color: PdfColors.black, fontSize: 16)),
        ],
      ),
    );
  }
}
