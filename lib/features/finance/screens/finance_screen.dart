import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/core/theme/app_theme.dart';
import 'package:flownote/core/providers/currency_provider.dart';
import 'package:flownote/features/finance/providers/transaction_provider.dart';
import 'package:flownote/widgets/common_widgets.dart';
import 'package:flownote/models/transaction_model.dart';
import 'package:intl/intl.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _activeFilter = 0; // 0=all, 1=income, 2=expense

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).loadTransactions();
      ref.read(transactionProvider.notifier).loadSummary();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);
    final symbol  = ref.watch(currencySymbolProvider);
    final summary = txState.summary;
    final income  = (summary?['total_income']  as num?)?.toDouble() ?? 0.0;
    final expense = (summary?['total_expense'] as num?)?.toDouble() ?? 0.0;
    final balance = (summary?['balance']       as num?)?.toDouble() ?? 0.0;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Keuangan',
              style: AppTextStyles.titleLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: _activeFilter != 0
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  ),
                  onPressed: _showFilterSheet,
                  tooltip: 'Filter',
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: isDark ? AppColors.darkBackground : AppColors.background,
                child: TabBar(
                  key: const ValueKey('finance_tab_bar'),
                  controller: _tabCtrl,
                  onTap: (i) {
                    setState(() => _activeFilter = i);
                    final types = [null, 'income', 'expense'];
                    ref.read(transactionProvider.notifier).setFilter(type: types[i]);
                  },
                  tabs: const [
                    Tab(text: 'Semua'),
                    Tab(text: 'Pemasukan'),
                    Tab(text: 'Pengeluaran'),
                  ],
                  labelStyle: AppTextStyles.labelLarge,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: AppColors.primary,
                  unselectedLabelColor:
                      isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                  dividerColor: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Summary strip ─────────────────────────────────────────
            _PremiumMonthlyStrip(
              income: income,
              expense: expense,
              balance: balance,
              symbol: symbol,
              isDark: isDark,
            ),
            // ── Transaction list ──────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(transactionProvider.notifier)
                    .loadTransactions(refresh: true),
                child: txState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : txState.transactions.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_rounded,
                            title: 'Belum ada transaksi',
                            subtitle: 'Tekan + untuk menambah transaksi pertama',
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 120),
                            itemCount: txState.transactions.length,
                            itemBuilder: (_, i) => _buildTile(
                              txState.transactions[i],
                              symbol,
                              isDark,
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(TransactionModel tx, String symbol, bool isDark) {
    final cat = tx.category;
    return TransactionTile(
      title:         tx.title,
      amount:        tx.amount,
      isIncome:      tx.isIncome,
      categoryName:  cat?.name,
      categoryColor: cat?.colorValue,
      categoryIcon:  cat?.iconData,
      date:          DateFormat('d MMM yyyy').format(tx.date),
      symbol:        symbol,
      onTap:         () => _showTxDetails(context, tx, symbol, isDark),
      onDelete: () async {
        final ok = await ref
            .read(transactionProvider.notifier)
            .deleteTransaction(tx.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok ? 'Transaksi dihapus' : 'Gagal menghapus'),
            backgroundColor: ok ? AppColors.income : AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      },
    );
  }

  void _showTxDetails(BuildContext context, TransactionModel tx, String symbol, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (tx.category?.colorValue ?? AppColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tx.category?.iconData ?? Icons.category_rounded,
                    color: tx.category?.colorValue ?? AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(tx.category?.name ?? 'Lainnya', style: AppTextStyles.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (tx.isIncome ? AppColors.income : AppColors.expense)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (tx.isIncome ? AppColors.income : AppColors.expense)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    tx.isIncome ? 'Pemasukan' : 'Pengeluaran',
                    style: TextStyle(
                      fontSize: 13,
                      color: tx.isIncome ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(tx.title, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${tx.isIncome ? '+' : '-'}${formatCurrencyFull(tx.amount, symbol)}',
              style: AppTextStyles.headlineLarge.copyWith(
                color: tx.isIncome ? AppColors.income : AppColors.expense,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVar : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Tanggal',
                    value: DateFormat('d MMMM yyyy').format(tx.date),
                    isDark: isDark,
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty) ...[
                    Divider(
                      height: 24,
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                    _DetailRow(
                      icon: Icons.note_rounded,
                      label: 'Catatan',
                      value: tx.note!,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textHint, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Filter Transaksi', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Hapus Filter'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() => _activeFilter = 0);
                  _tabCtrl.animateTo(0);
                  ref.read(transactionProvider.notifier).clearFilter();
                  Navigator.pop(ctx);
                },
              )),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 16,
            color: isDark ? AppColors.darkTextSec : AppColors.textSecondary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? AppColors.darkTextSec : AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.bodyMedium),
          ],
        ),
      ],
    );
  }
}

// ── Premium Monthly Strip ─────────────────────────────────────────────────────
class _PremiumMonthlyStrip extends StatelessWidget {
  final double income, expense, balance;
  final String symbol;
  final bool isDark;

  const _PremiumMonthlyStrip({
    required this.income,
    required this.expense,
    required this.balance,
    required this.symbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Savings rate
    final total    = income + expense;
    final savingsPct = total > 0 ? (income - expense) / total : 0.0;
    final displayPct = savingsPct.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _FinanceStat(
                label: 'Pemasukan',
                amount: income,
                color: AppColors.income,
                symbol: symbol,
                icon: Icons.arrow_downward_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 48,
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              const SizedBox(width: 8),
              _FinanceStat(
                label: 'Pengeluaran',
                amount: expense,
                color: AppColors.expense,
                symbol: symbol,
                icon: Icons.arrow_upward_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 48,
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              const SizedBox(width: 8),
              _FinanceStat(
                label: 'Saldo',
                amount: balance,
                color: balance >= 0 ? AppColors.primary : AppColors.expense,
                symbol: symbol,
                icon: Icons.account_balance_wallet_rounded,
                isDark: isDark,
              ),
            ],
          ),
          if (income > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Tabungan bulan ini',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(displayPct * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: displayPct > 0.2 ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: displayPct,
                minHeight: 6,
                backgroundColor:
                    isDark ? AppColors.darkSurfaceVar : AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  displayPct > 0.2 ? AppColors.income : AppColors.expense,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  final String label, symbol;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _FinanceStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.symbol,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCurrencyCompact(amount.abs(), symbol),
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
