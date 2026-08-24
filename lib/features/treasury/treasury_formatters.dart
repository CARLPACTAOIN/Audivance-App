import '../../core/domain/money.dart';
import '../audit/domain/audit_models.dart';

Money? parsePhpMoney(String input) {
  final normalized = input
      .trim()
      .replaceAll(',', '')
      .replaceFirst(RegExp(r'^PHP\s+', caseSensitive: false), '');
  if (normalized.isEmpty) {
    return null;
  }

  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);
  if (match == null) {
    return null;
  }

  final pesos = int.tryParse(match.group(1)!);
  if (pesos == null) {
    return null;
  }
  final centavosText = (match.group(2) ?? '').padRight(2, '0');
  final centavos = centavosText.isEmpty ? 0 : int.parse(centavosText);
  return Money.centavos((pesos * 100) + centavos);
}

String formatPhpMoney(Money money) {
  final sign = money.centavos < 0 ? '-' : '';
  final absolute = money.centavos.abs();
  final pesos = absolute ~/ 100;
  final centavos = absolute % 100;
  final pesosText = _formatInteger(pesos);
  if (centavos == 0) {
    return '${sign}PHP $pesosText';
  }
  return '${sign}PHP $pesosText.${centavos.toString().padLeft(2, '0')}';
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String treasurySourceTypeLabel(TreasuryFundSourceType type) {
  return switch (type) {
    TreasuryFundSourceType.previousAdmin => 'Fund from previous admin',
    TreasuryFundSourceType.studentCollections => 'Student Collections',
    TreasuryFundSourceType.donationSponsor => 'Donation / Sponsor',
    TreasuryFundSourceType.incomeGeneratingProfit => 'Income generating profit',
    TreasuryFundSourceType.ppmp => 'PPMP',
  };
}

String fundMovementTypeLabel(FundMovementType type) {
  return switch (type) {
    FundMovementType.addFund => 'Add Fund',
    FundMovementType.budgetAllocation => 'Budget Allocation',
    FundMovementType.budgetAdjustment => 'Budget Adjustment',
    FundMovementType.fundRelease => 'Fund Release',
    FundMovementType.transfer => 'Transfer',
    FundMovementType.returnRefund => 'Return / Refund',
    FundMovementType.liquidationSubmitted => 'Liquidation Submitted',
    FundMovementType.reimbursementPayment => 'Reimbursement Payment',
  };
}

String _formatInteger(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i += 1) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
