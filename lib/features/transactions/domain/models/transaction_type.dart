enum TransactionType {
  expense,
  credit,
}

extension TransactionTypeX on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.expense:
        return 'EXPENSE';
      case TransactionType.credit:
        return 'CREDIT';
    }
  }

  static TransactionType fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'EXPENSE':
        return TransactionType.expense;
      case 'CREDIT':
        return TransactionType.credit;
      default:
        throw ArgumentError(
          'Unknown transaction type: $value',
        );
    }
  }
}
