import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/core/theme/app_theme.dart';
import 'package:flownote/core/providers/currency_provider.dart';
import 'package:flownote/features/finance/providers/transaction_provider.dart';
import 'package:flownote/features/dashboard/providers/dashboard_provider.dart';
import 'package:flownote/widgets/common_widgets.dart';
import 'package:intl/intl.dart';

/// Versi aplikasi — update setiap upgrade
const String kAppVersion = '2.0.0';

/// Bottom sheet untuk menambah transaksi baru
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  final _dateCtrl   = TextEditingController(); // ← sekarang field, bukan dibuat ulang

  String   _type      = 'expense';
  DateTime _date      = DateTime.now();
  String?  _categoryId;
  String?  _categoryName;
  String?  _categoryIcon;
  String?  _categoryColor;
  bool     _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('d MMM yyyy').format(_date);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  /// Parse amount: hapus titik & koma agar "1.000.000" atau "1,000" jadi 1000000
  double _parseAmount(String raw) {
    // Hapus semua titik dan koma (format Indonesia: 1.000.000)
    final cleaned = raw.replaceAll('.', '').replaceAll(',', '').trim();
    return double.parse(cleaned);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountCtrl.text);

    setState(() => _isLoading = true);

    try {
      final ok = await ref.read(transactionProvider.notifier).createTransaction(
        title:         _titleCtrl.text.trim(),
        amount:        amount,
        type:          _type,
        categoryId:    _categoryId,
        categoryName:  _categoryName,
        categoryIcon:  _categoryIcon,
        categoryColor: _categoryColor,
        date:          DateFormat('yyyy-MM-dd').format(_date),
        note:          _noteCtrl.text.isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        final msg = ok ? 'Transaksi berhasil ditambahkan!' : 'Gagal menambah transaksi';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: ok ? AppColors.income : AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString().substring(0, e.toString().length.clamp(0, 100))}'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ));
      }
      return;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(categoriesProvider);
    final symbol     = ref.watch(currencySymbolProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Tambah Transaksi', style: AppTextStyles.titleLarge),
              const SizedBox(height: 20),

              // ── Tipe toggle ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVar : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  _TypeButton(
                    label: 'Pengeluaran',
                    icon: Icons.arrow_upward_rounded,
                    selected: _type == 'expense',
                    color: AppColors.expense,
                    onTap: () => setState(() {
                      _type = 'expense';
                      _categoryId = null;
                      _categoryName = null;
                    }),
                  ),
                  _TypeButton(
                    label: 'Pemasukan',
                    icon: Icons.arrow_downward_rounded,
                    selected: _type == 'income',
                    color: AppColors.income,
                    onTap: () => setState(() {
                      _type = 'income';
                      _categoryId = null;
                      _categoryName = null;
                    }),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Jumlah ──────────────────────────────────────────────────
              Text('Jumlah ($symbol)', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: '0',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(symbol, style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    )),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                  final cleaned = v.replaceAll('.', '').replaceAll(',', '');
                  if (double.tryParse(cleaned) == null) return 'Jumlah tidak valid';
                  if (double.parse(cleaned) <= 0) return 'Jumlah harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Deskripsi ────────────────────────────────────────────────
              AppTextField(
                label: 'Deskripsi',
                hint: 'cth. Makan siang, Gaji...',
                controller: _titleCtrl,
                prefixIcon: Icons.edit_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // ── Kategori ─────────────────────────────────────────────────
              Text('Kategori', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              categories.when(
                data: (cats) {
                  final filtered = cats.where((c) =>
                    c.type == _type || c.type == 'both'
                  ).toList();

                  if (filtered.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVar : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Tidak ada kategori tersedia',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _categoryId,
                    hint: const Text('Pilih kategori'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: filtered.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(children: [
                        Icon(c.iconData, size: 18, color: c.colorValue),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ]),
                    )).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      final cat = filtered.firstWhere((c) => c.id == v);
                      setState(() {
                        _categoryId    = v;
                        _categoryName  = cat.name;
                        _categoryIcon  = cat.icon;
                        _categoryColor = cat.color;
                      });
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, __) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expenseLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gagal memuat kategori', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600)),
                      Text(e.toString(), style: const TextStyle(fontSize: 11, color: AppColors.expense)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Tanggal ──────────────────────────────────────────────────
              AppTextField(
                label: 'Tanggal',
                hint: 'Pilih tanggal',
                controller: _dateCtrl,
                prefixIcon: Icons.calendar_today_rounded,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _date = picked;
                      _dateCtrl.text = DateFormat('d MMM yyyy').format(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // ── Catatan ──────────────────────────────────────────────────
              AppTextField(
                label: 'Catatan (opsional)',
                hint: 'Informasi tambahan...',
                controller: _noteCtrl,
                prefixIcon: Icons.note_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Simpan Transaksi',
                isLoading: _isLoading,
                onTap: _submit,
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label, required this.icon, required this.selected,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? color : AppColors.textHint),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.labelLarge.copyWith(
                color: selected ? color : AppColors.textHint,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
