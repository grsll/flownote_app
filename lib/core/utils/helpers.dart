/// Formats currency in Rupiah (compact)
String formatCurrency(double amount) {
  if (amount >= 1000000000) {
    return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}B';
  } else if (amount >= 1000000) {
    return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
  }
  return 'Rp ${amount.toStringAsFixed(0)}';
}

/// Full currency format for detail view
String formatCurrencyFull(double amount) {
  final parts  = amount.toStringAsFixed(0).split('');
  final result = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) result.write('.');
    result.write(parts[i]);
  }
  return 'Rp $result';
}
