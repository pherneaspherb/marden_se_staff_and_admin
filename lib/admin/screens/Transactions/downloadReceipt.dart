import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// Web-only import
import 'dart:html' as html;

/// Deep Purple Material Color (Hex #673AB7)
final deepPurple = const PdfColor.fromInt(0xFF673AB7);

/// Generates the styled PDF bytes
Future<Uint8List> _generatePdfBytes(
  Map<String, dynamic> orderData,
  Map<String, dynamic> customerData,
) async {
  final pdf = pw.Document();

  final orderId = orderData['orderId'] ?? 'No ID';
  final totalRaw = orderData['totalAmount'] ?? orderData['totalPrice'] ?? '0.00';
  final double total = double.tryParse(totalRaw.toString()) ?? 0.00;
  final serviceType = orderData['serviceType'] ?? orderData['containerType'] ?? 'N/A';

  final customerName = '${customerData['firstName']} ${customerData['lastName']}';

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: deepPurple, width: 2),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'Marden Services Receipt',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: deepPurple,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1.5, color: deepPurple),
            pw.SizedBox(height: 12),

            _buildRow('Order ID:', orderId),
            _buildRow('Customer:', customerName),
            _buildRow('Service Type:', serviceType),
            _buildRow('Total Amount:', 'PHP ${total.toStringAsFixed(2)}'),

            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1.2),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Thank you for choosing Marden!',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return pdf.save();
}

/// Reusable styled row
pw.Widget _buildRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          flex: 5,
          child: pw.Text(value),
        ),
      ],
    ),
  );
}

/// Public function to generate and download PDF depending on platform
Future<void> generateAndDownloadPdf(
  Map<String, dynamic> orderData,
  Map<String, dynamic> customerData,
) async {
  final pdfBytes = await _generatePdfBytes(orderData, customerData);

  if (kIsWeb) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '${orderData['orderId'] ?? 'receipt'}.pdf';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } else {
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}
