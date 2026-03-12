import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Currency Provider ─────────────────────────────────────────────────────────
/// Daftar mata uang yang tersedia
const Map<String, Map<String, String>> kCurrencyList = {
  'IDR': {'symbol': 'Rp', 'name': 'Rupiah (IDR)', 'locale': 'id'},
  'USD': {'symbol': '\$', 'name': 'Dollar AS (USD)', 'locale': 'en'},
  'EUR': {'symbol': '€', 'name': 'Euro (EUR)', 'locale': 'de'},
  'SGD': {'symbol': 'S\$', 'name': 'Dollar Singapura (SGD)', 'locale': 'en'},
  'MYR': {'symbol': 'RM', 'name': 'Ringgit Malaysia (MYR)', 'locale': 'ms'},
};

/// Provider untuk kode mata uang yang dipilih (default IDR)
final selectedCurrencyProvider = StateProvider<String>((ref) => 'IDR');

/// Provider symbol mata uang
final currencySymbolProvider = Provider<String>((ref) {
  final code = ref.watch(selectedCurrencyProvider);
  return kCurrencyList[code]?['symbol'] ?? 'Rp';
});

// ── Currency Format Helpers ───────────────────────────────────────────────────

/// Format angka dengan titik sebagai separator ribuan (format Indonesia)
String formatWithDots(double amount) {
  final isNegative = amount < 0;
  final absAmount = amount.abs();
  final part = absAmount.toStringAsFixed(0);
  final buf = StringBuffer();
  int count = 0;
  for (int i = part.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buf.write('.');
    buf.write(part[i]);
    count++;
  }
  final formatted = buf.toString().split('').reversed.join('');
  return isNegative ? '-$formatted' : formatted;
}

/// Format kompak dengan titik (mis. 1.500.000 → 1,5M)
String formatCurrencyCompact(double amount, String symbol) {
  final abs = amount.abs();
  final prefix = amount < 0 ? '-' : '';
  if (abs >= 1000000000) return '$prefix$symbol ${(abs / 1000000000).toStringAsFixed(1)}M';
  if (abs >= 1000000)    return '$prefix$symbol ${(abs / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000)       return '$prefix$symbol ${(abs / 1000).toStringAsFixed(0)}K';
  return '$prefix$symbol ${abs.toStringAsFixed(0)}';
}

/// Format penuh dengan titik sebagai separator (mis. Rp 12.450.000)
String formatCurrencyFull(double amount, String symbol) {
  return '$symbol ${formatWithDots(amount)}';
}

// ── Currency Selector Widget ──────────────────────────────────────────────────
class CurrencySelectorButton extends ConsumerWidget {
  const CurrencySelectorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(selectedCurrencyProvider);

    return GestureDetector(
      onTap: () => _showCurrencyPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    final currentCode = ref.read(selectedCurrencyProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Mata Uang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...kCurrencyList.entries.map((entry) {
              final selected = entry.key == currentCode;
              return ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      entry.value['symbol']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: selected ? const Color(0xFF4F46E5) : Colors.black87,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? const Color(0xFF4F46E5) : null,
                  ),
                ),
                subtitle: Text(entry.value['name']!),
                trailing: selected
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5))
                    : null,
                onTap: () {
                  ref.read(selectedCurrencyProvider.notifier).state = entry.key;
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
