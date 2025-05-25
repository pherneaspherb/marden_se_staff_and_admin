import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';

final deepPurple = const PdfColor.fromInt(0xFF673AB7);

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

Future<Pricing> fetchPricing() async {
  final firestore = FirebaseFirestore.instance;

  final laundryDoc =
      await firestore.collection('services').doc('laundry').get();
  final waterDoc = await firestore.collection('services').doc('water').get();

  Map<String, double> toPriceMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return data.map((key, value) {
      if (value == null) return MapEntry(key, 0.0);
      if (value is num) return MapEntry(key, value.toDouble());
      return MapEntry(key, 0.0);
    });
  }

  final laundryData = toPriceMap(laundryDoc);

  return Pricing(
    laundryPrices: laundryData,
    extrasPrices: laundryData,
    waterPrices: toPriceMap(waterDoc),
  );
}

final keyAliases = {
  'wash_dry': 'wash_and_dry',
  'pick_up': 'pickup',
  'tube': 'tube_container',
  'jug': 'jug_container',
  'per_kg': 'per_kilogram',
};

String _normalizeKey(String key) {
  var cleaned = key.toLowerCase();

  cleaned = cleaned.replaceAll('&', 'and');

  cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]+'), '');

  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

  cleaned = cleaned.replaceAll(' ', '_');

  cleaned = cleaned.trim();

  return keyAliases[cleaned] ?? cleaned;
}

double _getPriceFromMap(Map<String, double> priceMap, String? key) {
  if (key == null) return 0.0;
  final normalizedKey = _normalizeKey(key);
  return priceMap[normalizedKey] ?? 0.0;
}

Future<Uint8List> _generatePdfBytes(
  Map<String, dynamic> orderData,
  Map<String, dynamic> customerData,
  bool isLaundry,
  Pricing pricing,
) async {
  final pdf = pw.Document();

  final orderId = orderData['orderId'] ?? 'No ID';
  final customerName =
      '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'
          .trim();

  double total = 0.0;

  final content = <pw.Widget>[
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
    pw.SizedBox(height: 20),
  ];

  if (isLaundry) {
    final serviceType = orderData['serviceType']?.toString() ?? 'N/A';
    final servicePrice = _getPriceFromMap(pricing.laundryPrices, serviceType);
    print(
      'ServiceType: "$serviceType" -> "${_normalizeKey(serviceType)}" -> PHP $servicePrice',
    );
    total += servicePrice;
    content.add(_buildPriceRow('Service Type:', serviceType, servicePrice));

    final extras = orderData['extras']?.toString();
    double extrasTotal = 0.0;
    if (extras != null &&
        extras.toLowerCase() != 'none' &&
        extras.trim().isNotEmpty) {
      final extrasList = extras
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);

      for (final e in extrasList) {
        final normalized = _normalizeKey(e);
        final price = _getPriceFromMap(pricing.extrasPrices, e);
        print('Extra: "$e" -> "$normalized" -> PHP $price');
        extrasTotal += price;
      }

      total += extrasTotal;
      content.add(_buildPriceRow('Extras:', extras, extrasTotal));
    }

    final weight =
        double.tryParse(orderData['weight']?.toString() ?? '0') ?? 0.0;
    final ratePerKg = _getPriceFromMap(pricing.laundryPrices, 'per_kilogram');
    final weightCost = weight * ratePerKg;
    print(
      'Weight: ${weight.toStringAsFixed(1)} kg * PHP $ratePerKg = PHP $weightCost',
    );
    total += weightCost;
    content.add(
      _buildPriceRow('Weight:', '${weight.toStringAsFixed(1)} kg', weightCost),
    );

    final deliveryMode = orderData['deliveryMode']?.toString() ?? 'N/A';
    final deliveryFee =
        deliveryMode.toLowerCase() == 'deliver'
            ? _getPriceFromMap(pricing.laundryPrices, 'deliver')
            : 0.0;
    print('Delivery Mode: "$deliveryMode" -> PHP $deliveryFee');
    total += deliveryFee;
    content.add(_buildPriceRow('Delivery Mode:', deliveryMode, deliveryFee));
  } else {
    final containerType = orderData['containerType']?.toString() ?? 'N/A';
    final containerPrice = _getPriceFromMap(pricing.waterPrices, containerType);
    final quantity =
        int.tryParse(orderData['quantity']?.toString() ?? '0') ?? 0;
    final deliveryMode = orderData['deliveryMode']?.toString() ?? 'N/A';

    final subtotal = containerPrice * quantity;
    final deliveryFee =
        deliveryMode.toLowerCase() == 'deliver'
            ? _getPriceFromMap(pricing.waterPrices, 'deliver')
            : 0.0;
    total = subtotal + deliveryFee;

    print(
      'Container: "$containerType" -> PHP $containerPrice x $quantity = PHP $subtotal',
    );
    print('Delivery Mode: "$deliveryMode" -> PHP $deliveryFee');

    content.addAll([
      _buildPriceRow('Container Type:', containerType, containerPrice),
      _buildRow('Quantity:', '$quantity'),
      _buildPriceRow('Delivery Mode:', deliveryMode, deliveryFee),
    ]);
  }

  content.addAll([
    pw.SizedBox(height: 20),
    pw.Divider(thickness: 1.2),
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
  ]);

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
              children: content,
            ),
          ),
    ),
  );

  return pdf.save();
}

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
            'PHP ${price.toStringAsFixed(2)}',
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

Future<void> generateAndDownloadPdf(
  Map<String, dynamic> orderData,
  Map<String, dynamic> customerData,
  bool isLaundry,
) async {
  final pricing = await fetchPricing();
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
