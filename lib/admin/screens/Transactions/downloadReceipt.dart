import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';

final deepPurple = const PdfColor.fromInt(0xFF673AB7);

/// Pricing model to hold prices fetched from Firestore
class Pricing {
  final Map<String, double> laundryPrices;
  final Map<String, double> extrasPrices;
  final Map<String, double> waterPrices;

  Pricing({
    required this.laundryPrices,
    required this.extrasPrices,
    required this.waterPrices,
  });
}

/// Fetch prices dynamically from Firestore
Future<Pricing> fetchPricing() async {
  final firestore = FirebaseFirestore.instance;

  final laundryDoc =
      await firestore.collection('services').doc('laundry').get();
  final extrasDoc = await firestore.collection('services').doc('extras').get();
  final waterDoc = await firestore.collection('services').doc('water').get();

  Map<String, double> toPriceMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return data.map((key, value) {
      final val = value;
      if (val == null) return MapEntry(key, 0.0);
      if (val is num) return MapEntry(key, val.toDouble());
      return MapEntry(key, 0.0);
    });
  }

  return Pricing(
    laundryPrices: toPriceMap(laundryDoc),
    extrasPrices: toPriceMap(extrasDoc),
    waterPrices: toPriceMap(waterDoc),
  );
}

/// Helper to safely get price from a map by key, returns 0.0 if key is null or missing
double _getPriceFromMap(Map<String, double> priceMap, String? key) {
  if (key == null) {
    // print('Price key is null');
    return 0.0;
  }
  final price = priceMap[key];
  if (price == null) {
    // print('Price missing for key: $key');
    return 0.0;
  }
  return price;
}

Future<Uint8List> _generatePdfBytes(
  Map<String, dynamic> orderData,
  Map<String, dynamic> customerData,
  bool isLaundry,
  Pricing pricing,
) async {
  final pdf = pw.Document();

  final orderId = orderData['orderId'] ?? 'No ID';
  final totalRaw =
      orderData['totalAmount'] ?? orderData['totalPrice'] ?? '0.00';
  final double total = double.tryParse(totalRaw.toString()) ?? 0.00;

  final customerName =
      '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'
          .trim();

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(32),
      build:
          (context) => pw.Container(
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

                // Common fields
                _buildRow('Order ID:', orderId),
                _buildRow('Customer:', customerName),

                pw.SizedBox(height: 20),

                // Service & pricing summary
                if (isLaundry) ...[
                  _buildPriceRow(
                    'Service Type:',
                    orderData['serviceType']?.toString() ?? 'N/A',
                    _getPriceFromMap(
                      pricing.laundryPrices,
                      orderData['serviceType']?.toString(),
                    ),
                  ),
                  if ((orderData['extras']?.toString().toLowerCase() ?? '') !=
                          'none' &&
                      orderData['extras'] != null)
                    _buildPriceRow(
                      'Extras:',
                      orderData['extras']?.toString() ?? '',
                      _getPriceFromMap(
                        pricing.extrasPrices,
                        orderData['extras']?.toString(),
                      ),
                    ),
                  _buildRow('Weight:', '${orderData['weight'] ?? 'N/A'} kg'),
                  _buildRow(
                    'Delivery Mode:',
                    orderData['deliveryMode']?.toString() ?? 'N/A',
                  ),
                ] else ...[
                  _buildPriceRow(
                    'Container Type:',
                    orderData['containerType']?.toString() ?? 'N/A',
                    _getPriceFromMap(
                      pricing.waterPrices,
                      orderData['containerType']?.toString(),
                    ),
                  ),
                  _buildRow('Quantity:', '${orderData['quantity'] ?? 'N/A'}'),
                  _buildRow(
                    'Delivery Mode:',
                    orderData['deliveryMode']?.toString() ?? 'N/A',
                  ),
                ],

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1.2),

                // Total amount
                _buildRow('Total Amount:', 'PHP ${total.toStringAsFixed(2)}'),

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

/// Row for label + value (no price)
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
        pw.Expanded(flex: 5, child: pw.Text(value)),
      ],
    ),
  );
}

/// Row for label + service name + price aligned right
pw.Widget _buildPriceRow(String label, String serviceName, double price) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(flex: 4, child: pw.Text(serviceName)),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            '₱${price.toStringAsFixed(2)}',
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

/// Call this function to generate and download the PDF receipt for a single order.
Future<void> generateAndDownloadPdf(
  Map<String, dynamic> orderData,
  Map<String, dynamic> customerData,
  bool isLaundry,
) async {
  final pricing = await fetchPricing(); // fetch prices from Firestore

  final pdfBytes = await _generatePdfBytes(
    orderData,
    customerData,
    isLaundry,
    pricing,
  );

  if (kIsWeb) {
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
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}
