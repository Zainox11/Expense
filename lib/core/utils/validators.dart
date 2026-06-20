/// Form field validators for input validation across the app.
/// Each validator returns null if valid, or an error message string if invalid.
class Validators {
  Validators._();

  /// Validates that a field is not empty
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates password with minimum requirements
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  /// Validates password strength with stricter rules
  static String? passwordStrong(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  /// Validates that confirm password matches the original
  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != originalPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  /// Validates a monetary amount
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required.';
    }

    // Remove commas and currency symbols for parsing
    final cleaned = value.replaceAll(RegExp(r'[,\$€£¥₹]'), '').trim();
    final parsed = double.tryParse(cleaned);

    if (parsed == null) {
      return 'Please enter a valid amount.';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than zero.';
    }
    if (parsed > 999999999) {
      return 'Amount is too large.';
    }
    return null;
  }

  /// Validates display name
  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters.';
    }
    return null;
  }

  /// Validates a note/description field (optional, but has max length)
  static String? note(String? value) {
    if (value != null && value.length > 500) {
      return 'Note must be less than 500 characters.';
    }
    return null;
  }

  /// Validates a category name
  static String? categoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required.';
    }
    if (value.trim().length > 30) {
      return 'Category name must be less than 30 characters.';
    }
    return null;
  }

  /// Validates budget amount
  static String? budgetAmount(String? value) {
    final amountError = amount(value);
    if (amountError != null) return amountError;

    final cleaned = value!.replaceAll(RegExp(r'[,\$€£¥₹]'), '').trim();
    final parsed = double.parse(cleaned);

    if (parsed < 1) {
      return 'Budget must be at least 1.';
    }
    return null;
  }
}
