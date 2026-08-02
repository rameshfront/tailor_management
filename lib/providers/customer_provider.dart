import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';

/// Provider for customer data
class CustomerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Customer> get customers => _filtered;
  List<Customer> get allCustomers => _customers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    _customers = await _db.getAllCustomers();
    _applyFilter();
    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_customers);
    } else {
      final q = _searchQuery.toLowerCase();
      _filtered = _customers.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.mobile.contains(q);
      }).toList();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await _db.insertCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _db.deleteCustomer(id);
    await loadCustomers();
  }

  Future<bool> isMobileDuplicate(String mobile, {int? excludeId}) async {
    final existing = await _db.getCustomerByMobile(mobile);
    if (existing == null) return false;
    if (excludeId != null && existing.id == excludeId) return false;
    return true;
  }

  Customer? getById(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
