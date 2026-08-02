/// Form validators
class Validators {
  Validators._();

  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 10 || cleaned.length > 13) {
      return 'Enter a valid phone number (10 digits)';
    }
    return null;
  }

  static String? amount(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Amount is required' : null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  static String? quantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid quantity';
    }
    return null;
  }
}
