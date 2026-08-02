import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/customer_card.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final customers = provider.customers;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone...',
                  border: InputBorder.none,
                ),
                onChanged: (q) => provider.search(q),
              )
            : const Text('Customers',
                style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  provider.clearSearch();
                }
              });
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
              ? _buildEmpty(context)
              : RefreshIndicator(
                  onRefresh: () => provider.loadCustomers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: customers.length,
                    itemBuilder: (ctx, i) {
                      final c = customers[i];
                      return CustomerCard(
                        customer: c,
                        onTap: () => _openDetail(c),
                        onEdit: () => _editCustomer(c),
                        onDelete: () => _deleteCustomer(c),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
          if (mounted) provider.loadCustomers();
        },
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  void _openDetail(Customer c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
    );
  }

  void _editCustomer(Customer c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddCustomerScreen(customer: c)),
    );
    if (mounted) context.read<CustomerProvider>().loadCustomers();
  }

  void _deleteCustomer(Customer c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
            'Delete ${c.name}? This will also delete all their orders.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<CustomerProvider>().deleteCustomer(c.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${c.name} deleted')),
        );
      }
    }
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 72, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No customers yet',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Tap + to add your first customer',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
