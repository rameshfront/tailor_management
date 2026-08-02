import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/order.dart';
import '../utils/helpers.dart';

/// Service for generating Excel reports
class ExcelService {
  ExcelService._();
  static final ExcelService instance = ExcelService._();

  CellStyle _headerStyle(Excel excel) {
    return CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#3F51B5'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
  }

  CellStyle _altRowStyle() {
    return CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E8EAF6'),
    );
  }

  Future<File> generateOrderReport({
    required String reportName,
    required String dateRange,
    required List<Order> orders,
    required String currency,
    required String shopName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Orders'];
    excel.setDefaultSheet('Orders');

    // Title
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('H1'),
    );
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('$shopName — $reportName');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('H2'),
    );
    final dateCell = sheet.cell(CellIndex.indexByString('A2'));
    dateCell.value = TextCellValue('Period: $dateRange | Generated: ${Helpers.formatDate(DateTime.now())}');
    dateCell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);

    // Header row
    final headers = [
      'Order No.',
      'Customer',
      'Phone',
      'Dress Type',
      'Dress Name',
      'Qty',
      'Total ($currency)',
      'Advance ($currency)',
      'Balance ($currency)',
      'Order Status',
      'Payment',
      'Order Date',
      'Delivery Date',
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _headerStyle(excel);
    }

    // Data rows
    for (var idx = 0; idx < orders.length; idx++) {
      final o = orders[idx];
      final rowIdx = idx + 4;
      final values = [
        o.orderNumber,
        o.customerName ?? '',
        o.customerMobile ?? '',
        o.dressType,
        o.dressName,
        o.quantity.toString(),
        _fmt(o.totalAmount),
        _fmt(o.advanceAmount),
        _fmt(o.balanceAmount),
        o.orderStatus,
        o.paymentStatus,
        _shortDate(o.orderDate),
        o.deliveryDate != null ? _shortDate(o.deliveryDate!) : '',
      ];
      for (var col = 0; col < values.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
        cell.value = TextCellValue(values[col]);
        if (idx.isOdd) cell.cellStyle = _altRowStyle();
      }
    }

    // Totals
    final totalRow = orders.length + 5;
    final totalRevenue = orders.fold(0.0, (s, o) => s + o.totalAmount);
    final totalCollected = orders.fold(0.0, (s, o) => s + o.advanceAmount);
    final totalPending = orders.fold(0.0, (s, o) => s + o.balanceAmount);

    void _addTotal(int col, String label, String value) {
      final labelCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow));
      labelCell.value = TextCellValue('TOTALS');
      labelCell.cellStyle = CellStyle(bold: true);

      final c = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: totalRow));
      c.value = TextCellValue(value);
      c.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#C5CAE9'),
      );
    }

    _addTotal(6, 'Total', _fmt(totalRevenue));
    _addTotal(7, 'Advance', _fmt(totalCollected));
    _addTotal(8, 'Balance', _fmt(totalPending));

    // Set column widths
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 16);
    }

    return _saveExcel(excel, reportName);
  }

  Future<File> generateDressWiseExcel({
    required String shopName,
    required List<Map<String, dynamic>> data,
    required String currency,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Dress Report'];
    excel.setDefaultSheet('Dress Report');

    final headers = ['Dress Type', 'Orders', 'Revenue ($currency)', 'Collected ($currency)', 'Pending ($currency)'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#3F51B5'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }
    for (var idx = 0; idx < data.length; idx++) {
      final row = data[idx];
      final values = [
        row['dress_type'] ?? '-',
        '${row['count'] ?? 0}',
        _fmt((row['total_revenue'] as num?)?.toDouble() ?? 0),
        _fmt((row['collected'] as num?)?.toDouble() ?? 0),
        _fmt((row['pending'] as num?)?.toDouble() ?? 0),
      ];
      for (var col = 0; col < values.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: idx + 1));
        cell.value = TextCellValue(values[col]);
        if (idx.isOdd) cell.cellStyle = _altRowStyle();
      }
    }
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18);
    }
    return _saveExcel(excel, 'dress_wise_report');
  }

  Future<File> generateCustomerExcel({
    required String shopName,
    required List<Map<String, dynamic>> data,
    required String currency,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Customers'];
    excel.setDefaultSheet('Customers');

    final headers = ['Name', 'Mobile', 'Orders', 'Total Spent ($currency)', 'Paid ($currency)', 'Balance ($currency)'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#3F51B5'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }
    for (var idx = 0; idx < data.length; idx++) {
      final row = data[idx];
      final values = [
        row['name'] ?? '-',
        row['mobile'] ?? '-',
        '${row['order_count'] ?? 0}',
        _fmt((row['total_spent'] as num?)?.toDouble() ?? 0),
        _fmt((row['paid'] as num?)?.toDouble() ?? 0),
        _fmt((row['balance'] as num?)?.toDouble() ?? 0),
      ];
      for (var col = 0; col < values.length; col++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: idx + 1));
        cell.value = TextCellValue(values[col]);
        if (idx.isOdd) cell.cellStyle = _altRowStyle();
      }
    }
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18);
    }
    return _saveExcel(excel, 'customer_report');
  }

  String _fmt(double v) => NumberFormat('#,##0.00').format(v);

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Future<File> _saveExcel(Excel excel, String name) async {
    final dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final path =
        '${dir.path}/${safeName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate Excel file');
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }
}
