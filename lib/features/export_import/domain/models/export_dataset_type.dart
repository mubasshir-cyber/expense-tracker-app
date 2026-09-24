/// Financial ledger dataset scope for exports.
enum ExportDatasetType {
  transactions,
  savingsGoals,
  debtsAndLoans,
  fullBackup;

  String get label {
    switch (this) {
      case ExportDatasetType.transactions:
        return 'Transactions';
      case ExportDatasetType.savingsGoals:
        return 'Savings Goals';
      case ExportDatasetType.debtsAndLoans:
        return 'Debts & Loans';
      case ExportDatasetType.fullBackup:
        return 'Full Financial Backup';
    }
  }

  String get description {
    switch (this) {
      case ExportDatasetType.transactions:
        return 'Income & Expense transaction ledger';
      case ExportDatasetType.savingsGoals:
        return 'Savings targets and contribution ledger';
      case ExportDatasetType.debtsAndLoans:
        return 'Debts, loans, interest, and repayment history';
      case ExportDatasetType.fullBackup:
        return 'All ledgers packaged as individual files in a ZIP archive';
    }
  }
}
