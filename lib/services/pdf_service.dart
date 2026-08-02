import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Service for generating PDF reports
class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  pw.TextStyle _header() => pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.indigo800,
      );

  pw.TextStyle _subHeader() => pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.indigo600,
      );

  pw.TextStyle _tableHeader() => pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );

  pw.TextStyle _body() => const pw.TextStyle(fontSize: 10);

  pw.Widget _buildHeader(String shopName, String reportName, String dateRange) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(shopName, style: _header()),
                pw.Text(reportName, style: _subHeader()),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(dateRange, style: _body()),
                pw.Text(
                  'Generated: ${Helpers.formatDate(DateTime.now())}',
                  style: _body(),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(color: PdfColors.indigo800, thickness: 2),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {bool bold = false}) {
    final style = bold
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)
        : _body();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  pw.TableRow _tableHeaderRow(List<String> cols) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.indigo800),
      children: cols
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(c, style: _tableHeader()),
              ))
          .toList(),
    );
  }

  pw.TableRow _tableDataRow(List<String> cells, bool alternate) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: alternate ? PdfColors.indigo50 : PdfColors.white,
      ),
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(c, style: _body()),
              ))
          .toList(),
    );
  }

  /// Generate an order-list report PDF
  Future<File> generateOrderReport({
    required String shopName,
    required String reportName,
    required String dateRange,
    required List<Order> orders,
    required String currency,
  }) async {
    final pdf = pw.Document();

    final totalRevenue = orders.fold(0.0, (s, o) => s + o.totalAmount);
    final totalCollected = orders.fold(0.0, (s, o) => s + o.advanceAmount);
    final totalPending = orders.fold(0.0, (s, o) => s + o.balanceAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(shopName, reportName, dateRange),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('$shopName | $reportName', style: _body()),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: _body()),
          ],
        ),
        build: (ctx) => [
          // Summary box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              children: [
                _buildSummaryRow('Total Orders', '${orders.length}'),
                _buildSummaryRow(
                    'Total Revenue', '$currency${_fmt(totalRevenue)}'),
                _buildSummaryRow(
                    'Amount Collected', '$currency${_fmt(totalCollected)}'),
                _buildSummaryRow(
                    'Pending Balance', '$currency${_fmt(totalPending)}',
                    bold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Table
          if (orders.isNotEmpty) ...[
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FixedColumnWidth(60),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
                6: const pw.FlexColumnWidth(1.5),
              },
              children: [
                _tableHeaderRow([
                  'Order No.',
                  'Customer',
                  'Dress',
                  'Date',
                  'Total',
                  'Paid',
                  'Balance',
                ]),
                ...orders.asMap().entries.map((e) {
                  final idx = e.key;
                  final o = e.value;
                  return _tableDataRow([
                    o.orderNumber,
                    o.customerName ?? '-',
                    '${o.dressType}\n${o.dressName}',
                    _shortDate(o.orderDate),
                    '$currency${_fmt(o.totalAmount)}',
                    '$currency${_fmt(o.advanceAmount)}',
                    '$currency${_fmt(o.balanceAmount)}',
                  ], idx.isOdd);
                }),
              ],
            ),
            pw.SizedBox(height: 12),
            // Grand total row
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.indigo100),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'GRAND TOTAL  |  Revenue: $currency${_fmt(totalRevenue)}  |  Collected: $currency${_fmt(totalCollected)}  |  Balance: $currency${_fmt(totalPending)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ],
              ),
            ),
          ] else ...[
            pw.Center(
              child: pw.Text('No orders found for this period.',
                  style: _body()),
            ),
          ],
        ],
      ),
    );

    return _savePdf(pdf, reportName);
  }

  /// Generate dress-wise report
  Future<File> generateDressWiseReport({
    required String shopName,
    required List<Map<String, dynamic>> data,
    required String currency,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(shopName, 'Dress-Wise Report',
            'All Time | ${Helpers.formatDate(DateTime.now())}'),
        build: (ctx) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _tableHeaderRow(['Dress Type', 'Orders', 'Revenue', 'Collected', 'Pending']),
              ...data.asMap().entries.map((e) {
                final idx = e.key;
                final row = e.value;
                return _tableDataRow([
                  row['dress_type'] ?? '-',
                  '${row['count'] ?? 0}',
                  '$currency${_fmt((row['total_revenue'] as num?)?.toDouble() ?? 0)}',
                  '$currency${_fmt((row['collected'] as num?)?.toDouble() ?? 0)}',
                  '$currency${_fmt((row['pending'] as num?)?.toDouble() ?? 0)}',
                ], idx.isOdd);
              }),
            ],
          ),
        ],
      ),
    );
    return _savePdf(pdf, 'dress_wise_report');
  }

  /// Generate customer-wise report
  Future<File> generateCustomerReport({
    required String shopName,
    required List<Map<String, dynamic>> data,
    required String currency,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(shopName, 'Customer-Wise Report',
            'All Time | ${Helpers.formatDate(DateTime.now())}'),
        build: (ctx) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _tableHeaderRow(['Customer', 'Mobile', 'Orders', 'Total Spent', 'Balance']),
              ...data.asMap().entries.map((e) {
                final idx = e.key;
                final row = e.value;
                return _tableDataRow([
                  row['name'] ?? '-',
                  row['mobile'] ?? '-',
                  '${row['order_count'] ?? 0}',
                  '$currency${_fmt((row['total_spent'] as num?)?.toDouble() ?? 0)}',
                  '$currency${_fmt((row['balance'] as num?)?.toDouble() ?? 0)}',
                ], idx.isOdd);
              }),
            ],
          ),
        ],
      ),
    );
    return _savePdf(pdf, 'customer_report');
  }

  String _fmt(double v) => NumberFormat('#,##0.00').format(v);

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd/MM/yy').format(dt);
  }

  Future<File> _savePdf(pw.Document pdf, String name) async {
    final dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final path =
        '${dir.path}/${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> printPdf(File file) async {
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }
}
