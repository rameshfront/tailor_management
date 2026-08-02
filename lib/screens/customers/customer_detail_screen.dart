import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/order.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/order_card.dart';
import '../orders/order_detail_screen.dart';
import 'add_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orders = await context
        .read<OrderProvider>()
        .getOrdersByCustomer(_customer.id!);
    if (mounted) {
      setState(() {
        _orders = orders;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<SettingsProvider>().currency;
    final totalSpent = _orders.fold(0.0, (s, o) => s + o.totalAmount);
    final totalBalance = _orders.fold(0.0, (s, o) => s + o.balanceAmount);
    final initials = _customer.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddCustomerScreen(customer: _customer),
                ),
              );
              if (mounted) {
                final updated = context
                    .read<CustomerProvider>()
                    .getById(_customer.id!);
                if (updated != null) {
                  setState(() => _customer = updated);
                }
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Customer header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_customer.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          text: _customer.mobile,
                        ),
                        if (_customer.address != null &&
                            _customer.address!.isNotEmpty)
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            text: _customer.address!,
                          ),
                        if (_customer.notes != null &&
                            _customer.notes!.isNotEmpty)
                          _InfoRow(
                            icon: Icons.notes_outlined,
                            text: _customer.notes!,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Orders',
                      value: '${_orders.length}',
                      icon: Icons.receipt_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Total Spent',
                      value: Helpers.formatCurrency(totalSpent, currency),
                      icon: Icons.payments_outlined,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Balance Due',
                      value: Helpers.formatCurrency(totalBalance, currency),
                      icon: Icons.account_balance_wallet_outlined,
                      color: totalBalance > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Orders section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Order History',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (_loading)
            const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()))
          else if (_orders.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 48,
                          color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 8),
                      Text('No orders yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final o = _orders[i];
                  return OrderCard(
                    order: o,
                    currency: currency,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: o.id!),
                      ),
                    ),
                  );
                },
                childCount: _orders.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
