import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/core/theme/app_theme.dart';
import 'package:flownote/core/providers/theme_provider.dart';
import 'package:flownote/core/providers/currency_provider.dart';
import 'package:flownote/features/auth/providers/auth_provider.dart';
import 'package:flownote/features/finance/providers/transaction_provider.dart';
import 'package:flownote/features/notes/providers/note_provider.dart';
import 'package:flownote/features/dashboard/providers/dashboard_provider.dart';
import 'package:flownote/features/dashboard/screens/main_scaffold.dart';
import 'package:flownote/models/transaction_model.dart';
import 'package:flownote/models/note_model.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).loadTransactions();
      ref.read(transactionProvider.notifier).loadSummary();
      ref.read(transactionProvider.notifier).loadChartData();
      ref.read(noteProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth    = ref.watch(authProvider);
    final txState = ref.watch(transactionProvider);
    final isDark  = ref.watch(isDarkModeProvider);
    final symbol  = ref.watch(currencySymbolProvider);

    final summary     = txState.summary;
    final allTime     = summary?['allTime'] as Map<String, dynamic>?;
    final balance     = (allTime?['balance']       as num?)?.toDouble() ?? 0.0;
    final monthIncome = (summary?['total_income']  as num?)?.toDouble() ?? 0.0;
    final monthExp    = (summary?['total_expense'] as num?)?.toDouble() ?? 0.0;

    final recent5   = txState.transactions.take(5).toList();
    final chartData = txState.chartData;

    final noteState   = ref.watch(noteProvider);
    final recentNotes = [
      ...noteState.tasks.where((t) => !t.isCompleted),
      ...noteState.notes,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayNotes = recentNotes.take(4).toList();

    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(transactionProvider.notifier).loadTransactions(refresh: true),
                ref.read(transactionProvider.notifier).loadSummary(),
                ref.read(transactionProvider.notifier).loadChartData(),
                ref.read(noteProvider.notifier).loadAll(refresh: true),
              ]);
            },
            displacement: 80,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────────
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness:
                        isDark ? Brightness.light : Brightness.dark,
                  ),
                  expandedHeight: 0,
                  title: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            auth.user?.name.split(' ').first ?? 'Pengguna',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    // Dark mode toggle
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVar
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    // Avatar
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              auth.user?.initials ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Content ──────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Kartu Saldo ───────────────────────────────────
                      _PremiumBalanceCard(
                        balance:  balance,
                        income:   monthIncome,
                        expense:  monthExp,
                        symbol:   symbol,
                        isDark:   isDark,
                      ),
                      const SizedBox(height: 28),

                      // ── Ringkasan & Catatan Swipeable ─────────────────
                      _SectionTitle(
                        title: 'Ringkasan Mingguan',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 190,
                        child: PageView(
                          controller: _pageCtrl,
                          onPageChanged: (idx) =>
                              setState(() => _currentPage = idx),
                          children: [
                            GestureDetector(
                              onTap: () => ref
                                  .read(navIndexProvider.notifier)
                                  .state = 3,
                              child: _WeeklyChart(
                                  chartData: chartData, symbol: symbol),
                            ),
                            ...displayNotes.map(
                              (note) => _DashNoteCard(note: note, isDark: isDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          1 + displayNotes.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPage == i ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Transaksi Terakhir ────────────────────────────
                      _SectionTitle(
                        title: 'Transaksi Terakhir',
                        isDark: isDark,
                        action: recent5.isNotEmpty ? 'Lihat Semua' : null,
                        onAction: () =>
                            ref.read(navIndexProvider.notifier).state = 1,
                      ),
                      const SizedBox(height: 12),

                      if (txState.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (recent5.isEmpty)
                        _EmptyDash(
                          icon: Icons.receipt_long_rounded,
                          msg: 'Belum ada transaksi.\nTekan + untuk menambah.',
                          isDark: isDark,
                        )
                      else
                        ...recent5
                            .map((tx) => _DashTxTile(tx: tx, symbol: symbol, isDark: isDark)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat pagi, ☀️';
    if (hour < 15) return 'Selamat siang, 🌤';
    if (hour < 18) return 'Selamat sore, 🌅';
    return 'Selamat malam, 🌙';
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.isDark,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                action!,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Premium Balance Card ──────────────────────────────────────────────────────
class _PremiumBalanceCard extends ConsumerWidget {
  final double balance, income, expense;
  final String symbol;
  final bool isDark;

  const _PremiumBalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.symbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6D28D9), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.40),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Saldo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatCurrencyFull(balance, symbol),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _CardStat(
                  label: 'PEMASUKAN',
                  amount: income,
                  symbol: symbol,
                  isIncome: true,
                )),
                const SizedBox(width: 12),
                Expanded(child: _CardStat(
                  label: 'PENGELUARAN',
                  amount: expense,
                  symbol: symbol,
                  isIncome: false,
                )),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label, symbol;
  final double amount;
  final bool isIncome;
  const _CardStat({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? const Color(0xFF34D399) : const Color(0xFFF87171);
    final icon  = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrencyCompact(amount, symbol),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly Chart Bar ──────────────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;
  final String symbol;
  const _WeeklyChart({required this.chartData, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (chartData.isEmpty) {
      return _ChartContainer(
        isDark: isDark,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 40, color: isDark ? AppColors.darkBorder : AppColors.border),
            const SizedBox(height: 8),
            Text(
              'Belum ada data minggu ini',
              style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextSec : AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    double maxVal = 1.0;
    for (final d in chartData) {
      final income  = (d['income']  as num?)?.toDouble() ?? 0;
      final expense = (d['expense'] as num?)?.toDouble() ?? 0;
      if (income  > maxVal) maxVal = income;
      if (expense > maxVal) maxVal = expense;
    }

    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return _ChartContainer(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkTextSec : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Minggu Ini',
                  style: AppTextStyles.labelSmall.copyWith(
                      color:
                          isDark ? AppColors.darkTextSec : AppColors.textSecondary)),
              const Spacer(),
              _Legend(color: AppColors.primary, label: 'Masuk'),
              const SizedBox(width: 12),
              _Legend(
                  color: AppColors.expense.withValues(alpha: 0.8), label: 'Keluar'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(chartData.length, (i) {
                final d       = chartData[i];
                final income  = (d['income']  as num?)?.toDouble() ?? 0;
                final expense = (d['expense'] as num?)?.toDouble() ?? 0;
                const maxH    = 80.0;
                final iH      = maxVal > 0 ? (income  / maxVal * maxH).clamp(4.0, maxH) : 4.0;
                final eH      = maxVal > 0 ? (expense / maxVal * maxH).clamp(4.0, maxH) : 4.0;
                final isToday = i == chartData.length - 1;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Bar(
                          height: iH,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.primaryLight.withValues(alpha: 0.4),
                          isToday: isToday,
                        ),
                        const SizedBox(width: 2),
                        _Bar(
                          height: eH,
                          color: isToday
                              ? AppColors.expense
                              : AppColors.expense.withValues(alpha: 0.35),
                          isToday: isToday,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: isToday ? 28 : 20,
                      height: isToday ? 18 : 14,
                      decoration: isToday
                          ? BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Center(
                        child: Text(
                          i < days.length ? days[i] : '',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                            color: isToday
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSec
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _ChartContainer({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
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
      child: child,
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  final bool isToday;
  const _Bar({required this.height, required this.color, this.isToday = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      width: isToday ? 16 : 13,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}

// ── Dashboard Transaction Tile ────────────────────────────────────────────────
class _DashTxTile extends StatelessWidget {
  final TransactionModel tx;
  final String symbol;
  final bool isDark;
  const _DashTxTile({required this.tx, required this.symbol, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cat      = tx.category;
    final catColor = cat?.colorValue ?? AppColors.primary;
    final now      = DateTime.now();
    final dateLabel = _dateLabel(tx.date, now);

    return GestureDetector(
      onTap: () => _showDetails(context, isDark),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon kategori
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat?.iconData ?? Icons.category_rounded,
                  color: catColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${cat?.name ?? 'Lainnya'} • $dateLabel',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSec : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Jumlah
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${tx.isIncome ? '+' : '-'}${formatCurrencyCompact(tx.amount, symbol)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: tx.isIncome ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (tx.isIncome ? AppColors.income : AppColors.expense)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tx.isIncome ? 'Masuk' : 'Keluar',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: tx.isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date, DateTime now) {
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return DateFormat('d MMM yyyy').format(date);
  }

  void _showDetails(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TxDetailSheet(tx: tx, symbol: symbol, isDark: isDark),
    );
  }
}

class _TxDetailSheet extends StatelessWidget {
  final TransactionModel tx;
  final String symbol;
  final bool isDark;
  const _TxDetailSheet({required this.tx, required this.symbol, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              width: 40,
              height: 4,
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
              Text(tx.category?.name ?? 'Lainnya',
                  style: AppTextStyles.titleMedium),
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
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkTextSec : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                DateFormat('d MMMM yyyy').format(tx.date),
                style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSec : AppColors.textSecondary),
              ),
            ],
          ),
          if (tx.note != null && tx.note!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVar : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_rounded,
                      size: 16,
                      color: isDark ? AppColors.darkTextSec : AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tx.note!, style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyDash extends StatelessWidget {
  final IconData icon;
  final String msg;
  final bool isDark;
  const _EmptyDash({required this.icon, required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            msg,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Note Card ───────────────────────────────────────────────────────
class _DashNoteCard extends ConsumerWidget {
  final NoteModel note;
  final bool isDark;

  const _DashNoteCard({required this.note, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = note.isTask ? AppColors.accent : AppColors.primary;
    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).state = 2,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    note.isTask ? Icons.task_alt_rounded : Icons.sticky_note_2_rounded,
                    color: accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  note.isTask ? 'Tugas' : 'Catatan',
                  style: AppTextStyles.labelSmall.copyWith(color: accent),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isDark ? AppColors.darkTextSec : AppColors.textHint),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              note.title,
              style: AppTextStyles.titleMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.content != null && note.content!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  note.content!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
