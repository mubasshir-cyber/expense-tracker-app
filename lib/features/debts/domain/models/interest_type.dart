/// Represents how interest is calculated on a debt or loan.
enum InterestType {
  /// Zero interest (Repayment = Principal).
  none('NONE'),

  /// Percentage of principal (Interest = Principal * Rate / 100).
  percentage('PERCENTAGE'),

  /// Flat fixed amount of interest added to principal.
  fixed('FIXED');

  const InterestType(this.dbValue);

  final String dbValue;

  static InterestType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PERCENTAGE':
      case 'PERCENT':
        return InterestType.percentage;
      case 'FIXED':
      case 'FLAT':
        return InterestType.fixed;
      case 'NONE':
      default:
        return InterestType.none;
    }
  }

  String get label {
    switch (this) {
      case InterestType.none:
        return 'No Interest';
      case InterestType.percentage:
        return 'Percentage (%)';
      case InterestType.fixed:
        return 'Fixed Amount (₹)';
    }
  }
}
