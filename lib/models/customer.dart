/// Customer model representing a tailor shop client
class Customer {
  final int? id;
  final String name;
  final String mobile;
  final String? address;
  final String? notes;
  final String createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.mobile,
    this.address,
    this.notes,
    required this.createdAt,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? mobile,
    String? address,
    String? notes,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      mobile: map['mobile'] as String,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, mobile: $mobile)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
