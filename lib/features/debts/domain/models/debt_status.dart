import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Database persisted lifecycle state of a debt or loan.
enum DebtStatus {
  active('ACTIVE'),
  settled('SETTLED'),
  cancelled('CANCELLED');

  const DebtStatus(this.dbValue);

  final String dbValue;

  static DebtStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SETTLED':
      case 'PAID':
      case 'CLOSED':
        return DebtStatus.settled;
      case 'CANCELLED':
      case 'VOID':
        return DebtStatus.cancelled;
      case 'ACTIVE':
      default:
        return DebtStatus.active;
    }
  }

  String get label {
    switch (this) {
      case DebtStatus.active:
        return 'Active';
      case DebtStatus.settled:
        return 'Settled';
      case DebtStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// True if settled or cancelled
  bool get isClosed => this == DebtStatus.settled || this == DebtStatus.cancelled;

  Color get color {
    switch (this) {
      case DebtStatus.active:
        return AppColors.primary;
      case DebtStatus.settled:
        return AppColors.credit;
      case DebtStatus.cancelled:
        return Colors.grey;
    }
  }
}
