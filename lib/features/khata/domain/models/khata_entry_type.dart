import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum KhataEntryType {
  /// Money, products, or services given to customer on credit (increases what customer owes).
  given('GIVEN', 'You Gave', '+', AppColors.expense),

  /// Payment or cash received from customer (decreases what customer owes).
  received('RECEIVED', 'You Got', '-', AppColors.credit);

  const KhataEntryType(
    this.value,
    this.displayName,
    this.sign,
    this.color,
  );

  final String value;
  final String displayName;
  final String sign;
  final Color color;

  static KhataEntryType fromString(String? val) {
    if (val == null) return KhataEntryType.given;
    final upper = val.toUpperCase().trim();
    if (upper == 'RECEIVED' || upper == 'PAYMENT' || upper == 'GOT') {
      return KhataEntryType.received;
    }
    return KhataEntryType.given;
  }
}
