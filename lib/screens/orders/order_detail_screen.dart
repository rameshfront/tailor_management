import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../delivery/delivery_screen.dart';
import 'add_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order =
        await context.read<OrderProvider>().getOrderById(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    await context.read<OrderProvider>().updateOrderStatus(widget.orderId, status);
    await _loadOrder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
    }
  }

  Future<void> _deleteOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text(
            'Delete order ${_order?.orderNumber}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<OrderProvider>().deleteOrder(widget.orderId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final order = _order!;
    final theme = Theme.of(context);
    final currency = context.watch<SettingsProvider>().currency;
    final statusColor = AppColors.statusColor(order.orderStatus);

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddOrderScreen(order: order)),
              );
              await _loadOrder();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'delete') _deleteOrder();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Order',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrder,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle, color: statusColor, size: 10),
                        const SizedBox(width: 6),
                        Text(
                          order.orderStatus.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status stepper
                    Row(
                      children: AppConstants.orderStatuses
                          .where((s) => s != 'Delivered')
                          .toList()
                          .asMap()
                          .entries
                          .map((e) {
                        final idx = e.key;
                        final status = e.value;
                        final currentIdx = AppConstants.orderStatuses
                            .indexOf(order.orderStatus);
                        final isDone = currentIdx > idx ||
                            order.orderStatus == status;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _updateStatus(status),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: isDone
                                      ? statusColor
                                      : theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    isDone ? Icons.check : Icons.circle,
                                    size: 12,
                                    color: isDone
                                        ? Colors.white
                                        : theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDone
                                        ? statusColor
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isDone
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Customer & Order Info
              _Section(
                title: 'Order Information',
                children: [
                  _Row('Order Number', order.orderNumber),
                  _Row('Customer', order.customerName ?? '-'),
                  _Row('Phone', order.customerMobile ?? '-'),
                  _Row('Order Date',
                      Helpers.formatDate(DateTime.parse(order.orderDate))),
                  if (order.deliveryDate != null)
                    _Row(
                      'Delivery Date',
                      Helpers.formatDate(DateTime.parse(order.deliveryDate!)),
                      valueColor: Helpers.isOverdue(order.deliveryDate) &&
                              !order.isDelivered
                          ? Colors.red
                          : null,
                    ),
                  if (order.deliveredAt != null)
                    _Row(
                      'Delivered On',
                      Helpers.formatDate(DateTime.parse(order.deliveredAt!)),
                      valueColor: Colors.green,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              _Section(
                title: 'Dress Details',
                children: [
                  _Row('Dress Type', order.dressType),
                  _Row('Dress Name', order.dressName),
                  _Row('Quantity', '${order.quantity}'),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _Row('Notes', order.notes!),
                ],
              ),

              // Measurements
              if (order.measurement != null &&
                  !order.measurement!.isEmpty) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Measurements (inches)',
                  children: order.measurement!.allMeasurements.entries
                      .where((e) => e.value != null)
                      .map((e) => _Row(e.key, '${e.value}\"'))
                      .toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Payment
              _Section(
                title: 'Payment',
                children: [
                  _Row(
                    'Total Amount',
                    Helpers.formatCurrency(order.totalAmount, currency),
                    bold: true,
                  ),
                  _Row(
                    'Amount Paid',
                    Helpers.formatCurrency(order.advanceAmount, currency),
                    valueColor: Colors.green,
                  ),
                  _Row(
                    'Balance Due',
                    Helpers.formatCurrency(order.balanceAmount, currency),
                    bold: true,
                    valueColor: order.balanceAmount > 0
                        ? Colors.red
                        : Colors.green,
                  ),
                  _Row('Payment Status', order.paymentStatus,
                      valueColor:
                          AppColors.paymentColor(order.paymentStatus)),
                  if (order.paymentMethod != null)
                    _Row('Payment Method', order.paymentMethod!),
                ],
              ),

              // Photos
              if (order.clothPhoto != null ||
                  order.referencePhoto != null ||
                  order.finishedPhoto != null) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Photos',
                  children: [
                    Row(
                      children: [
                        if (order.clothPhoto != null)
                          Expanded(
                              child: _PhotoView(
                                  label: 'Cloth',
                                  path: order.clothPhoto!)),
                        if (order.referencePhoto != null)
                          Expanded(
                              child: _PhotoView(
                                  label: 'Reference',
                                  path: order.referencePhoto!)),
                        if (order.finishedPhoto != null)
                          Expanded(
                              child: _PhotoView(
                                  label: 'Finished',
                                  path: order.finishedPhoto!)),
                      ],
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              if (order.orderStatus != AppConstants.statusDelivered) ...[
                if (order.orderStatus == AppConstants.statusReady)
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryScreen(order: order),
                        ),
                      );
                      await _loadOrder();
                      if (mounted) {
                        context.read<OrderProvider>().loadDashboardStats();
                      }
                    },
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Mark as Delivered'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: Colors.green,
                    ),
                  ),
                if (order.orderStatus != AppConstants.statusReady)
                  OutlinedButton.icon(
                    onPressed: () {
                      final statuses = AppConstants.orderStatuses;
                      final idx = statuses.indexOf(order.orderStatus);
                      if (idx < statuses.length - 1) {
                        _updateStatus(statuses[idx + 1]);
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      'Move to ${_nextStatus(order.orderStatus)}',
                    ),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Order Delivered',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  String _nextStatus(String current) {
    final statuses = AppConstants.orderStatuses;
    final idx = statuses.indexOf(current);
    return idx < statuses.length - 1 ? statuses[idx + 1] : current;
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _Row(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoView extends StatelessWidget {
  final String label;
  final String path;

  const _PhotoView({required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(
                child: InteractiveViewer(
                  child: Image.file(File(path)),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
