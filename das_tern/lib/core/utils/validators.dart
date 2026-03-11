class Validators {
  static String? requiredField(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'This field is required';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'This field is required';
    }

    final double? number = double.tryParse(value);
    if (number == null || number <= 0) {
      return message ?? 'Enter a valid positive number';
    }
    return null;
  }
}
