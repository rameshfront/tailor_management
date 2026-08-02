import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/settings_provider.dart';
import '../../database/database_helper.dart';
import '../../widgets/order_card.dart';
import '../orders/order_detail_screen.dart';
import '../delivery/delivery_screen.dart';
import '../../providers/order_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Order> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    final orders = await DatabaseHelper.instance.searchOrders(query.trim());
    if (mounted) {
      setState(() {
        _results = orders;
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.watch<SettingsProvider>().currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _controller,
              hintText: 'Search by name, phone, order no., dress type...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    },
                  )
              ],
              onChanged: _search,
              onSubmitted: _search,
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Text('Filter: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                ...['Customer Name', 'Phone', 'Order No.', 'Dress Type']
                    .map((label) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(label),
                            visualDensity: VisualDensity.compact,
                          ),
                        )),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? _buildSearchPrompt(theme)
                    : _results.isEmpty
                        ? _buildNoResults(theme)
                        : ListView.builder(
                            padding:
                                const EdgeInsets.only(bottom: 80),
                            itemCount: _results.length,
                            itemBuilder: (ctx, i) {
                              final o = _results[i];
                              return OrderCard(
                                order: o,
                                currency: currency,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(
                                          orderId: o.id!),
                                    ),
                                  );
                                  if (mounted) {
                                    _search(_controller.text);
                                  }
                                },
                                onDeliver:
                                    o.orderStatus == 'Ready'
                                        ? () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    DeliveryScreen(
                                                        order: o),
                                              ),
                                            );
                                            if (mounted) {
                                              context.read<OrderProvider>().loadDashboardStats();
                                              _search(_controller.text);
                                            }
                                          }
                                        : null,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPrompt(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search,
              size: 72, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('Search Orders & Customers',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            'Enter a customer name, phone number,\norder number, or dress type',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 72, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No results found',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Try a different search term',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
