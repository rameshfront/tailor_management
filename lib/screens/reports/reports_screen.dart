import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/excel_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

enum ReportType { daily, weekly, monthly, yearly, income, pendingBalance, dressWise, customerWise, topCustomers }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportType _selectedReport = ReportType.daily;
  List<Order> _orders = [];
  List<Map<String, dynamic>> _tableData = [];
  bool _loading = false;
  String _dateRange = '';

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    final provider = context.read<OrderProvider>();
    final now = DateTime.now();
    List<Order> orders = [];
    List<Map<String, dynamic>> tableData = [];

    switch (_selectedReport) {
      case ReportType.daily:
        orders = await provider.getOrdersByDateRange(
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
        _dateRange = Helpers.formatDate(now);
        break;
      case ReportType.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        orders = await provider.getOrdersByDateRange(
          DateTime(start.year, start.month, start.day),
          DateTime(end.year, end.month, end.day, 23, 59, 59),
        );
        _dateRange = '${Helpers.formatDate(start)} – ${Helpers.formatDate(end)}';
        break;
      case ReportType.monthly:
        orders = await provider.getOrdersByDateRange(
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
        _dateRange = DateFormat('MMMM yyyy').format(now);
        break;
      case ReportType.yearly:
        orders = await provider.getOrdersByDateRange(
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
        _dateRange = '${now.year}';
        break;
      case ReportType.income:
        orders = await provider.getOrdersByDateRange(
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
        _dateRange = 'This Month — ${DateFormat('MMMM yyyy').format(now)}';
        break;
      case ReportType.pendingBalance:
        final all = await provider.getOrdersByDateRange(
          DateTime(2020),
          DateTime(2030),
        );
        orders = all.where((o) => o.paymentStatus != AppConstants.paymentPaid).toList();
        _dateRange = 'All Pending';
        break;
      case ReportType.dressWise:
        tableData = await provider.getDressWiseReport();
        _dateRange = 'All Time';
        break;
      case ReportType.customerWise:
        tableData = await provider.getCustomerWiseReport();
        _dateRange = 'All Time';
        break;
      case ReportType.topCustomers:
        tableData = await provider.getTopCustomers();
        _dateRange = 'All Time';
        break;
    }

    if (mounted) {
      setState(() {
        _orders = orders;
        _tableData = tableData;
        _loading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    final settings = context.read<SettingsProvider>();
    final name = _reportName();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Generating PDF...'),
        ]),
      ),
    );

    try {
      File file;
      if (_selectedReport == ReportType.dressWise) {
        file = await PdfService.instance.generateDressWiseReport(
          shopName: settings.shopName,
          data: _tableData,
          currency: settings.currency,
        );
      } else if (_selectedReport == ReportType.customerWise ||
          _selectedReport == ReportType.topCustomers) {
        file = await PdfService.instance.generateCustomerReport(
          shopName: settings.shopName,
          data: _tableData,
          currency: settings.currency,
        );
      } else {
        file = await PdfService.instance.generateOrderReport(
          shopName: settings.shopName,
          reportName: name,
          dateRange: _dateRange,
          orders: _orders,
          currency: settings.currency,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        await Share.shareXFiles([XFile(file.path)], text: '$name PDF');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    final settings = context.read<SettingsProvider>();
    final name = _reportName();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Generating Excel...'),
        ]),
      ),
    );

    try {
      File file;
      if (_selectedReport == ReportType.dressWise) {
        file = await ExcelService.instance.generateDressWiseExcel(
          shopName: settings.shopName,
          data: _tableData,
          currency: settings.currency,
        );
      } else if (_selectedReport == ReportType.customerWise ||
          _selectedReport == ReportType.topCustomers) {
        file = await ExcelService.instance.generateCustomerExcel(
          shopName: settings.shopName,
          data: _tableData,
          currency: settings.currency,
        );
      } else {
        file = await ExcelService.instance.generateOrderReport(
          reportName: name,
          dateRange: _dateRange,
          orders: _orders,
          currency: settings.currency,
          shopName: settings.shopName,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        await Share.shareXFiles([XFile(file.path)], text: '$name Excel');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Excel Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _reportName() {
    switch (_selectedReport) {
      case ReportType.daily: return 'Daily Report';
      case ReportType.weekly: return 'Weekly Report';
      case ReportType.monthly: return 'Monthly Report';
      case ReportType.yearly: return 'Yearly Report';
      case ReportType.income: return 'Income Report';
      case ReportType.pendingBalance: return 'Pending Balance Report';
      case ReportType.dressWise: return 'Dress-Wise Report';
      case ReportType.customerWise: return 'Customer-Wise Report';
      case ReportType.topCustomers: return 'Top Customers';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<SettingsProvider>().currency;
    final totalRevenue = _orders.fold(0.0, (s, o) => s + o.totalAmount);
    final totalCollected = _orders.fold(0.0, (s, o) => s + o.advanceAmount);
    final totalBalance = _orders.fold(0.0, (s, o) => s + o.balanceAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _loading ? null : _exportPdf,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: _loading ? null : _exportExcel,
            tooltip: 'Export Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Report type selector
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              children: [
                _Chip(label: 'Daily', selected: _selectedReport == ReportType.daily, onTap: () { setState(() => _selectedReport = ReportType.daily); _loadReport(); }),
                _Chip(label: 'Weekly', selected: _selectedReport == ReportType.weekly, onTap: () { setState(() => _selectedReport = ReportType.weekly); _loadReport(); }),
                _Chip(label: 'Monthly', selected: _selectedReport == ReportType.monthly, onTap: () { setState(() => _selectedReport = ReportType.monthly); _loadReport(); }),
                _Chip(label: 'Yearly', selected: _selectedReport == ReportType.yearly, onTap: () { setState(() => _selectedReport = ReportType.yearly); _loadReport(); }),
                _Chip(label: 'Income', selected: _selectedReport == ReportType.income, onTap: () { setState(() => _selectedReport = ReportType.income); _loadReport(); }),
                _Chip(label: 'Pending', selected: _selectedReport == ReportType.pendingBalance, onTap: () { setState(() => _selectedReport = ReportType.pendingBalance); _loadReport(); }),
                _Chip(label: 'Dress-wise', selected: _selectedReport == ReportType.dressWise, onTap: () { setState(() => _selectedReport = ReportType.dressWise); _loadReport(); }),
                _Chip(label: 'Customer-wise', selected: _selectedReport == ReportType.customerWise, onTap: () { setState(() => _selectedReport = ReportType.customerWise); _loadReport(); }),
                _Chip(label: 'Top Customers', selected: _selectedReport == ReportType.topCustomers, onTap: () { setState(() => _selectedReport = ReportType.topCustomers); _loadReport(); }),
              ],
            ),
          ),

          // Report header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_reportName(),
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold)),
                      Text(_dateRange,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary stats (for order-based reports)
          if (_selectedReport != ReportType.dressWise &&
              _selectedReport != ReportType.customerWise &&
              _selectedReport != ReportType.topCustomers &&
              !_loading) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Orders',
                      value: '${_orders.length}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Revenue',
                      value: Helpers.formatCurrency(totalRevenue, currency),
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Balance',
                      value: Helpers.formatCurrency(totalBalance, currency),
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(theme, currency),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, String currency) {
    // Dress-wise / Customer-wise / Top Customers
    if (_selectedReport == ReportType.dressWise) {
      return _buildDressWiseTable(theme, currency);
    }
    if (_selectedReport == ReportType.customerWise ||
        _selectedReport == ReportType.topCustomers) {
      return _buildCustomerTable(theme, currency);
    }

    // Order list
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 72, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No data for this period',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _orders.length,
      itemBuilder: (ctx, i) {
        final o = _orders[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                AppColors.statusColor(o.orderStatus).withOpacity(0.15),
            child: Text(
              '${i + 1}',
              style: TextStyle(
                  color: AppColors.statusColor(o.orderStatus),
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
          title: Text('${o.orderNumber} — ${o.customerName ?? ""}'),
          subtitle: Text(
              '${o.dressType} • ${Helpers.formatDate(DateTime.parse(o.orderDate))}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatCurrency(o.totalAmount, currency),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (o.balanceAmount > 0)
                Text(
                  'Bal: ${Helpers.formatCurrency(o.balanceAmount, currency)}',
                  style: const TextStyle(
                      color: Colors.red, fontSize: 11),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDressWiseTable(ThemeData theme, String currency) {
    if (_tableData.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Table(
        border: TableBorder.all(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer),
            children: ['Dress Type', 'Orders', 'Revenue', 'Balance']
                .map((h) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(h,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12)),
                    ))
                .toList(),
          ),
          ..._tableData.asMap().entries.map((e) {
            final idx = e.key;
            final row = e.value;
            return TableRow(
              decoration: BoxDecoration(
                  color: idx.isOdd
                      ? theme.colorScheme.surfaceContainerHighest
                      : null),
              children: [
                _TableCell(row['dress_type']?.toString() ?? '-'),
                _TableCell('${row['count'] ?? 0}'),
                _TableCell(Helpers.formatCurrency(
                    (row['total_revenue'] as num?)?.toDouble() ?? 0,
                    currency)),
                _TableCell(Helpers.formatCurrency(
                    (row['pending'] as num?)?.toDouble() ?? 0,
                    currency)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomerTable(ThemeData theme, String currency) {
    if (_tableData.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Table(
        border: TableBorder.all(color: theme.colorScheme.outlineVariant),
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer),
            children: ['Customer', 'Orders', 'Spent']
                .map((h) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(h,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12)),
                    ))
                .toList(),
          ),
          ..._tableData.asMap().entries.map((e) {
            final idx = e.key;
            final row = e.value;
            return TableRow(
              decoration: BoxDecoration(
                  color: idx.isOdd
                      ? theme.colorScheme.surfaceContainerHighest
                      : null),
              children: [
                _TableCell(row['name']?.toString() ?? '-'),
                _TableCell('${row['order_count'] ?? 0}'),
                _TableCell(Helpers.formatCurrency(
                    (row['total_spent'] as num?)?.toDouble() ?? 0,
                    currency)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14)),
          Text(label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;

  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
