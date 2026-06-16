class Validators {
  Validators._();

  static String? validateMerchantName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Merchant name is required';
    }
    if (value.trim().length < 2) {
      return 'Merchant name must be at least 2 characters';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Enter a valid number';
    }
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    if (amount > 10000000) {
      return 'Amount seems too large';
    }
    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

  static String? validateNotes(String? value) {
    // Notes are optional
    if (value != null && value.length > 500) {
      return 'Notes must be under 500 characters';
    }
    return null;
  }
}
