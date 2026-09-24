import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// Represents whether the user owes money (Liability) or is owed money (Asset).
enum DebtType {
  /// Money you borrowed from someone. You need to repay them.
  youOwe('YOU_OWE'),

  /// Money you lent to someone. You should receive repayment.
  youAreOwed('YOU_ARE_OWED');

  const DebtType(this.dbValue);

  final String dbValue;

  static DebtType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'YOU_OWE':
      case 'DEBT':
      case 'BORROWED':
      case 'LIABILITY':
        return DebtType.youOwe;
      case 'YOU_ARE_OWED':
      case 'LOAN':
      case 'LENT':
      case 'ASSET':
      default:
        return DebtType.youAreOwed;
    }
  }

  String get label {
    switch (this) {
      case DebtType.youOwe:
        return 'You Owe';
      case DebtType.youAreOwed:
        return 'You Are Owed';
    }
  }

  String get actionLabel {
    switch (this) {
      case DebtType.youOwe:
        return 'You need to pay';
      case DebtType.youAreOwed:
        return 'You should receive';
    }
  }

  String get counterpartyLabel {
    switch (this) {
      case DebtType.youOwe:
        return 'Lender / Creditor';
      case DebtType.youAreOwed:
        return 'Borrower / Debtor';
    }
  }

  IconData get icon {
    switch (this) {
      case DebtType.youOwe:
        return LucideIcons.arrowUpRight;
      case DebtType.youAreOwed:
        return LucideIcons.arrowDownLeft;
    }
  }

  Color get color {
    switch (this) {
      case DebtType.youOwe:
        return AppColors.error;
      case DebtType.youAreOwed:
        return AppColors.credit;
    }
  }
}
