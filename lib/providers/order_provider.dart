import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/measurement.dart';
import '../models/order.dart';

/// Provider for order data
class OrderProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Order> _orders = [];
  List<Order> _filtered = [];
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = false;

  List<Order> get orders => _filtered;
  List<Order> get allOrders => _orders;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    _orders = await _db.getAllOrders();
    _filtered = List.from(_orders);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDashboardStats() async {
    _dashboardStats = await _db.getDashboardStats();
    notifyListeners();
  }

  void filterByStatus(String? status) {
    if (status == null || status.isEmpty) {
      _filtered = List.from(_orders);
    } else {
      _filtered = _orders.where((o) => o.orderStatus == status).toList();
    }
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) {
      _filtered = List.from(_orders);
    } else {
      final q = query.toLowerCase();
      _filtered = _orders.where((o) {
        return (o.customerName?.toLowerCase().contains(q) ?? false) ||
            (o.customerMobile?.contains(q) ?? false) ||
            o.orderNumber.toLowerCase().contains(q) ||
            o.dressType.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<Order?> getOrderById(int id) async {
    return _db.getOrderById(id);
  }

  Future<List<Order>> getOrdersByCustomer(int customerId) async {
    return _db.getOrdersByCustomer(customerId);
  }

  Future<int> addOrder(Order order, Measurement? measurement) async {
    final id = await _db.insertOrder(order);
    if (measurement != null) {
      final m = Measurement(
        orderId: id,
        chest: measurement.chest,
        shoulder: measurement.shoulder,
        neck: measurement.neck,
        sleeve: measurement.sleeve,
        waist: measurement.waist,
        hip: measurement.hip,
        pantLength: measurement.pantLength,
        bottom: measurement.bottom,
        customMeasurements: measurement.customMeasurements,
      );
      await _db.insertOrUpdateMeasurement(m);
    }
    await loadOrders();
    await loadDashboardStats();
    return id;
  }

  Future<void> updateOrder(Order order, Measurement? measurement) async {
    await _db.updateOrder(order);
    if (measurement != null && order.id != null) {
      await _db.insertOrUpdateMeasurement(
        measurement.copyWith(orderId: order.id),
      );
    }
    await loadOrders();
    await loadDashboardStats();
  }

  Future<void> deleteOrder(int id) async {
    await _db.deleteOrder(id);
    await loadOrders();
    await loadDashboardStats();
  }

  Future<void> updateOrderStatus(int id, String status) async {
    final order = _orders.firstWhere((o) => o.id == id);
    final updated = order.copyWith(
      orderStatus: status,
      deliveredAt: status == 'Delivered' ? DateTime.now().toIso8601String() : order.deliveredAt,
    );
    await _db.updateOrder(updated);
    await loadOrders();
    await loadDashboardStats();
  }

  Future<void> markDelivered({
    required int orderId,
    required double balancePaid,
    required String paymentMethod,
    required String deliveryDate,
  }) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    final newAdvance = order.advanceAmount + balancePaid;
    final paymentStatus = newAdvance >= order.totalAmount ? 'Paid' : 'Partial';
    final updated = order.copyWith(
      orderStatus: 'Delivered',
      advanceAmount: newAdvance,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      deliveredAt: deliveryDate,
    );
    await _db.updateOrder(updated);
    await loadOrders();
    await loadDashboardStats();
  }

  // ─── Reports data ─────────────────────────────────────────────────────────

  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end) async {
    return _db.getOrdersByDateRange(start, end);
  }

  Future<List<Map<String, dynamic>>> getDressWiseReport() async {
    return _db.getDressWiseReport();
  }

  Future<List<Map<String, dynamic>>> getCustomerWiseReport() async {
    return _db.getCustomerWiseReport();
  }

  Future<List<Map<String, dynamic>>> getTopCustomers() async {
    return _db.getTopCustomers();
  }
}
