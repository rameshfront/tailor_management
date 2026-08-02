import 'measurement.dart';

/// Order model representing a tailor order
class Order {
  final int? id;
  final String orderNumber;
  final int customerId;
  final String? customerName; // Joined field, not stored
  final String? customerMobile; // Joined field, not stored
  final String orderDate;
  final String? deliveryDate;
  final String dressType;
  final String dressName;
  final int quantity;
  final String? notes;
  final String? clothPhoto;
  final String? referencePhoto;
  final String? finishedPhoto;
  final double totalAmount;
  final double advanceAmount;
  // balance = total - advance (computed)
  final String paymentStatus; // Pending / Partial / Paid
  final String orderStatus;   // Pending / Cutting / Stitching / Ready / Delivered
  final String? paymentMethod; // Cash / UPI / Card
  final String? deliveredAt;
  final String createdAt;

  // Joined measurement (not stored in order table)
  final Measurement? measurement;

  const Order({
    this.id,
    required this.orderNumber,
    required this.customerId,
    this.customerName,
    this.customerMobile,
    required this.orderDate,
    this.deliveryDate,
    required this.dressType,
    required this.dressName,
    required this.quantity,
    this.notes,
    this.clothPhoto,
    this.referencePhoto,
    this.finishedPhoto,
    required this.totalAmount,
    required this.advanceAmount,
    required this.paymentStatus,
    required this.orderStatus,
    this.paymentMethod,
    this.deliveredAt,
    required this.createdAt,
    this.measurement,
  });

  double get balanceAmount => totalAmount - advanceAmount;

  bool get isDelivered => orderStatus == 'Delivered';
  bool get isReady => orderStatus == 'Ready';
  bool get isPaid => paymentStatus == 'Paid';

  Order copyWith({
    int? id,
    String? orderNumber,
    int? customerId,
    String? customerName,
    String? customerMobile,
    String? orderDate,
    String? deliveryDate,
    String? dressType,
    String? dressName,
    int? quantity,
    String? notes,
    String? clothPhoto,
    String? referencePhoto,
    String? finishedPhoto,
    double? totalAmount,
    double? advanceAmount,
    String? paymentStatus,
    String? orderStatus,
    String? paymentMethod,
    String? deliveredAt,
    String? createdAt,
    Measurement? measurement,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      dressType: dressType ?? this.dressType,
      dressName: dressName ?? this.dressName,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      clothPhoto: clothPhoto ?? this.clothPhoto,
      referencePhoto: referencePhoto ?? this.referencePhoto,
      finishedPhoto: finishedPhoto ?? this.finishedPhoto,
      totalAmount: totalAmount ?? this.totalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      measurement: measurement ?? this.measurement,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'order_date': orderDate,
      'delivery_date': deliveryDate,
      'dress_type': dressType,
      'dress_name': dressName,
      'quantity': quantity,
      'notes': notes,
      'cloth_photo': clothPhoto,
      'reference_photo': referencePhoto,
      'finished_photo': finishedPhoto,
      'total_amount': totalAmount,
      'advance_amount': advanceAmount,
      'payment_status': paymentStatus,
      'order_status': orderStatus,
      'payment_method': paymentMethod,
      'delivered_at': deliveredAt,
      'created_at': createdAt,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      orderNumber: map['order_number'] as String,
      customerId: map['customer_id'] as int,
      customerName: map['customer_name'] as String?,
      customerMobile: map['customer_mobile'] as String?,
      orderDate: map['order_date'] as String,
      deliveryDate: map['delivery_date'] as String?,
      dressType: map['dress_type'] as String,
      dressName: map['dress_name'] as String,
      quantity: map['quantity'] as int,
      notes: map['notes'] as String?,
      clothPhoto: map['cloth_photo'] as String?,
      referencePhoto: map['reference_photo'] as String?,
      finishedPhoto: map['finished_photo'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      advanceAmount: (map['advance_amount'] as num).toDouble(),
      paymentStatus: map['payment_status'] as String,
      orderStatus: map['order_status'] as String,
      paymentMethod: map['payment_method'] as String?,
      deliveredAt: map['delivered_at'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  @override
  String toString() =>
      'Order(id: $id, orderNumber: $orderNumber, status: $orderStatus)';
}
