import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/dashboard_card.dart';
import '../customers/add_customer_screen.dart';
import '../orders/add_order_screen.dart';
import '../orders/orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final stats = orderProvider.dashboardStats;
    final currency = settings.currency;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<OrderProvider>().loadDashboardStats();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  settings.shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatDate(DateTime.now()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dashboard stats grid
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  DashboardCard(
                    title: "Today's Orders",
                    value: '${stats['todayOrders'] ?? 0}',
                    icon: Icons.add_shopping_cart_outlined,
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdersScreen(filterStatus: null),
                      ),
                    ),
                  ),
                  DashboardCard(
                    title: 'Pending Orders',
                    value: '${stats['pendingOrders'] ?? 0}',
                    icon: Icons.pending_outlined,
                    color: AppColors.warning,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdersScreen(
                            filterStatus: AppConstants.statusPending),
                      ),
                    ),
                  ),
                  DashboardCard(
                    title: 'Ready for Delivery',
                    value: '${stats['readyOrders'] ?? 0}',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.success,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdersScreen(
                            filterStatus: AppConstants.statusReady),
                      ),
                    ),
                  ),
                  DashboardCard(
                    title: 'Delivered',
                    value: '${stats['deliveredOrders'] ?? 0}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.info,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdersScreen(
                            filterStatus: AppConstants.statusDelivered),
                      ),
                    ),
                  ),
                  DashboardCard(
                    title: "Today's Income",
                    value: Helpers.formatCurrency(
                        (stats['todayIncome'] as double?) ?? 0.0, currency),
                    icon: Icons.trending_up_outlined,
                    color: Colors.teal,
                  ),
                  DashboardCard(
                    title: 'Pending Balance',
                    value: Helpers.formatCurrency(
                        (stats['pendingBalance'] as double?) ?? 0.0, currency),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.error,
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.person_add_outlined,
                            label: 'New Customer',
                            color: AppColors.primary,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AddCustomerScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_task_outlined,
                            label: 'New Order',
                            color: AppColors.accent,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddOrderScreen(),
                                ),
                              );
                              if (mounted) {
                                context.read<OrderProvider>().loadDashboardStats();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.people_outline,
                            label: 'Customers',
                            color: Colors.teal,
                            onTap: () {
                              // Switch to customers tab — handled by MainNav
                              final nav = context.findAncestorStateOfType<_HomeScreenState>();
                              // Navigate via parent — just push
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddOrderScreen()),
          );
          if (mounted) {
            context.read<OrderProvider>().loadDashboardStats();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
