import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/order_card.dart';
import '../delivery/delivery_screen.dart';
import 'add_order_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final String? filterStatus;

  const OrdersScreen({super.key, this.filterStatus});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<String?> _tabs = [
    null,
    AppConstants.statusPending,
    AppConstants.statusCutting,
    AppConstants.statusStitching,
    AppConstants.statusReady,
    AppConstants.statusDelivered,
  ];

  @override
  void initState() {
    super.initState();
    final initialTab =
        widget.filterStatus != null ? _tabs.indexOf(widget.filterStatus) : 0;
    _tabCtrl = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialTab < 0 ? 0 : initialTab,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final currency = context.watch<SettingsProvider>().currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Cutting'),
            Tab(text: 'Stitching'),
            Tab(text: 'Ready'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: _tabs.map((status) {
                final orders = status == null
                    ? provider.allOrders
                    : provider.allOrders
                        .where((o) => o.orderStatus == status)
                        .toList();

                if (orders.isEmpty) {
                  return _buildEmpty(context, status);
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadOrders(),
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) {
                      final o = orders[i];
                      return OrderCard(
                        order: o,
                        currency: currency,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailScreen(orderId: o.id!),
                            ),
                          );
                          if (mounted) provider.loadOrders();
                        },
                        onDeliver: o.orderStatus ==
                                AppConstants.statusReady
                            ? () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DeliveryScreen(order: o),
                                  ),
                                );
                                if (mounted) {
                                  provider.loadOrders();
                                  provider.loadDashboardStats();
                                }
                              }
                            : null,
                      );
                    },
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddOrderScreen()),
          );
          if (mounted) {
            provider.loadOrders();
            provider.loadDashboardStats();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, String? status) {
    final theme = Theme.of(context);
    final label = status ?? 'any';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            status == null ? 'No orders yet' : 'No $label orders',
            style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text('Tap + to create a new order',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
