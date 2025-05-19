import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// Only for web
import 'dart:html' as html;

/// Generates PDF document as bytes
Future<Uint8List> _generatePdfBytes(
  Map<String, dynamic> orderData,
  Map<String, dynamic> customerData,
) async {
  final pdf = pw.Document();

  final orderId = orderData['orderId'] ?? 'No ID';
  final total = orderData['totalAmount'] ?? orderData['totalPrice'] ?? '0.00';
  final serviceType =
      orderData['serviceType'] ?? orderData['containerType'] ?? 'N/A';

  pdf.addPage(
    pw.Page(
      build:
          (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Receipt for Order $orderId',
                style: pw.TextStyle(fontSize: 24),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Customer: ${customerData['firstName']} ${customerData['lastName']}',
              ),
              pw.Text('Service: $serviceType'),
              pw.Text('Total Amount: ₱$total'),
              pw.Text('Order ID: $orderId'),
            ],
          ),
    ),
  );

  return pdf.save();
}

/// Public function to generate and download PDF depending on platform
Future<void> generateAndDownloadPdf(
  Map<String, dynamic> orderData,
  Map<String, dynamic> customerData,
) async {
  final pdfBytes = await _generatePdfBytes(orderData, customerData);

  if (kIsWeb) {
    // Web: use browser download
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor =
        html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = '${orderData['orderId'] ?? 'receipt'}.pdf';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } else {
    // Mobile/Desktop: use printing package to print/save
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}
