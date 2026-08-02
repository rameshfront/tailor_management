import 'dart:convert';

/// Measurement model for an order
class Measurement {
  final int? id;
  final int orderId;
  final double? chest;
  final double? shoulder;
  final double? neck;
  final double? sleeve;
  final double? waist;
  final double? hip;
  final double? pantLength;
  final double? bottom;
  /// Key-value pairs for custom measurements
  final Map<String, double> customMeasurements;

  const Measurement({
    this.id,
    required this.orderId,
    this.chest,
    this.shoulder,
    this.neck,
    this.sleeve,
    this.waist,
    this.hip,
    this.pantLength,
    this.bottom,
    this.customMeasurements = const {},
  });

  Measurement copyWith({
    int? id,
    int? orderId,
    double? chest,
    double? shoulder,
    double? neck,
    double? sleeve,
    double? waist,
    double? hip,
    double? pantLength,
    double? bottom,
    Map<String, double>? customMeasurements,
  }) {
    return Measurement(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      chest: chest ?? this.chest,
      shoulder: shoulder ?? this.shoulder,
      neck: neck ?? this.neck,
      sleeve: sleeve ?? this.sleeve,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      pantLength: pantLength ?? this.pantLength,
      bottom: bottom ?? this.bottom,
      customMeasurements: customMeasurements ?? this.customMeasurements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      'chest': chest,
      'shoulder': shoulder,
      'neck': neck,
      'sleeve': sleeve,
      'waist': waist,
      'hip': hip,
      'pant_length': pantLength,
      'bottom': bottom,
      'custom_measurements': jsonEncode(customMeasurements),
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    Map<String, double> custom = {};
    final customStr = map['custom_measurements'] as String?;
    if (customStr != null && customStr.isNotEmpty) {
      final decoded = jsonDecode(customStr) as Map<String, dynamic>;
      custom = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    return Measurement(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      chest: (map['chest'] as num?)?.toDouble(),
      shoulder: (map['shoulder'] as num?)?.toDouble(),
      neck: (map['neck'] as num?)?.toDouble(),
      sleeve: (map['sleeve'] as num?)?.toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      pantLength: (map['pant_length'] as num?)?.toDouble(),
      bottom: (map['bottom'] as num?)?.toDouble(),
      customMeasurements: custom,
    );
  }

  /// Returns all measurements as a labeled map for display
  Map<String, double?> get allMeasurements => {
        'Chest': chest,
        'Shoulder': shoulder,
        'Neck': neck,
        'Sleeve': sleeve,
        'Waist': waist,
        'Hip': hip,
        'Pant Length': pantLength,
        'Bottom': bottom,
        ...customMeasurements.map((k, v) => MapEntry(k, v)),
      };

  bool get isEmpty =>
      chest == null &&
      shoulder == null &&
      neck == null &&
      sleeve == null &&
      waist == null &&
      hip == null &&
      pantLength == null &&
      bottom == null &&
      customMeasurements.isEmpty;
}
