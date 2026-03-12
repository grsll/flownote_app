import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flownote/core/theme/app_theme.dart';
import 'package:flownote/features/finance/providers/transaction_provider.dart';
import 'package:flownote/core/providers/currency_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier)
        ..loadSummary(month: _selectedMonth, year: _selectedYear)
        ..loadChartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);
    final summary = txState.summary;
    final symbol  = ref.watch(currencySymbolProvider);
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    final monthly   = summary?['monthly'] as Map<String, dynamic>?;
    final income    = double.tryParse(monthly?['income']?.toString() ?? '0') ?? 0;
    final expense   = double.tryParse(monthly?['expense']?.toString() ?? '0') ?? 0;
    final breakdown = summary?['categoryBreakdown'] as List? ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(transactionProvider.notifier)
              .loadSummary(month: _selectedMonth, year: _selectedYear);
          await ref.read(transactionProvider.notifier).loadChartData();
        },
        child: CustomScrollView(
          slivers: [
            // ── Premium Header ───────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -30,
                      top: -10,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  'Analisis Keuangan',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Month Selector ──────────────────────────────────────
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: _MonthSelector(
                        month: _selectedMonth,
                        year: _selectedYear,
                        isDark: isDark,
                        onChanged: (m, y) {
                          setState(() { _selectedMonth = m; _selectedYear = y; });
                          ref.read(transactionProvider.notifier)
                              .loadSummary(month: m, year: y);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Summary Cards ───────────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Row(
                        children: [
                          Expanded(child: _SummaryCard(
                            label: 'Pemasukan',
                            amount: income,
                            symbol: symbol,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.auto_graph_rounded,
                            isDark: isDark,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _SummaryCard(
                            label: 'Pengeluaran',
                            amount: expense,
                            symbol: symbol,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            icon: Icons.money_off_csred_rounded,
                            isDark: isDark,
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Category Breakdown ──────────────────────────────────
                    if (breakdown.isNotEmpty) ...[
                      FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Distribusi Pengeluaran',
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.border,
                                ),
                                boxShadow: isDark ? null : [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.05),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _CategoryPieChart(
                                    breakdown: breakdown,
                                    isDark: isDark,
                                    totalExpense: expense,
                                    symbol: symbol,
                                  ),
                                  const SizedBox(height: 32),
                                  _CategoryLegend(
                                    breakdown: breakdown,
                                    totalExpense: expense,
                                    symbol: symbol,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // ── 6 Months Bar Chart ──────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tren 6 Bulan Terakhir',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _MonthlyBarChart(
                            chartData: txState.chartData,
                            isDark: isDark,
                            symbol: symbol,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Components ──────────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final int month, year;
  final bool isDark;
  final void Function(int m, int y) onChanged;

  const _MonthSelector({required this.month, required this.year, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun', 'Jul','Agu','Sep','Okt','Nov','Des'];
    
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
            onTap: () {
              final newM = month == 1 ? 12 : month - 1;
              final newY = month == 1 ? year - 1 : year;
              onChanged(newM, newY);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.primary),
            ),
          ),
          Text(
            '${months[month - 1]} $year',
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          InkWell(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
            onTap: () {
              final newM = month == 12 ? 1 : month + 1;
              final newY = month == 12 ? year + 1 : year;
              onChanged(newM, newY);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Gradient gradient;
  final IconData icon;
  final bool isDark;
  final String symbol;

  const _SummaryCard({
    required this.label, required this.amount, required this.symbol,
    required this.gradient, required this.icon, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Icon(icon, size: 90, color: Colors.white.withValues(alpha: 0.15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatShortAmount(amount, symbol),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List breakdown;
  final bool isDark;
  final double totalExpense;
  final String symbol;

  const _CategoryPieChart({required this.breakdown, required this.isDark, required this.totalExpense, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final expenses = breakdown.where((b) => b['type'] == 'expense').toList();
    if (expenses.isEmpty) return const SizedBox.shrink();

    final total = expenses.fold<double>(0, (s, b) =>
        s + (double.tryParse(b['total'].toString()) ?? 0));

    final sections = expenses.asMap().entries.map((entry) {
      final b     = entry.value;
      final pct   = (double.tryParse(b['total'].toString()) ?? 0) / total;
      final hex   = (b['color'] as String? ?? '#6366F1').replaceAll('#', '');
      final color = Color(int.parse('FF$hex', radix: 16));
      return PieChartSectionData(
        value:       pct * 100,
        color:       color,
        radius:      pct > 0.4 ? 50 : 40,
        showTitle:   false,
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 75,
              sectionsSpace: 6,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total', style: TextStyle(color: isDark ? AppColors.darkTextSec : AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                _formatShortAmount(totalExpense, symbol),
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final List breakdown;
  final double totalExpense;
  final String symbol;
  final bool isDark;

  const _CategoryLegend({required this.breakdown, required this.totalExpense, required this.symbol, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final expenses = breakdown.where((b) => b['type'] == 'expense').toList();
    expenses.sort((a,b) {
       final aT = double.tryParse(a['total'].toString()) ?? 0;
       final bT = double.tryParse(b['total'].toString()) ?? 0;
       return bT.compareTo(aT);
    });

    return Column(
      children: expenses.map((b) {
        final hex   = (b['color'] as String? ?? '#6366F1').replaceAll('#', '');
        final color = Color(int.parse('FF$hex', radix: 16));
        final amount = double.tryParse(b['total'].toString()) ?? 0;
        final pct    = totalExpense > 0 ? (amount / totalExpense) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          b['category'] as String? ?? 'Lainnya',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _formatShortAmount(amount, symbol),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: isDark ? AppColors.darkSurfaceVar : AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;
  final bool isDark;
  final String symbol;

  const _MonthlyBarChart({required this.chartData, required this.isDark, required this.symbol});

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: const Center(child: Text('Data belum tersedia')),
      );
    }

    final months = <String, Map<String, double>>{};
    for (final row in chartData) {
      final key = '${row['year']?.toString() ?? ''}-${row['month']?.toString() ?? ''}';
      months.putIfAbsent(key, () => {'income': 0, 'expense': 0});
      final type = row['type'] as String? ?? '';
      months[key]![type] = double.tryParse(row['total']?.toString() ?? '0') ?? 0;
    }

    final entries   = months.entries.toList();
    final maxY = entries.fold<double>(0, (m, e) =>
        [m, e.value['income'] ?? 0, e.value['expense'] ?? 0].reduce((a, b) => a > b ? a : b)
    );

    final barGroups = entries.asMap().entries.map((e) {
      final income  = e.value.value['income'] ?? 0;
      final expense = e.value.value['expense'] ?? 0;
      return BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(
          toY: income,
          color: AppColors.income,
          width: 10,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: expense,
          color: AppColors.expense,
          width: 10,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ], barsSpace: 6);
    }).toList();

    return Container(
      height: 320,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 100 : maxY * 1.2,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
              dashArray: [6, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (val, _) {
                        return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                                val == 0 ? '' : _formatShortAmount(val, ''),
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.right,
                            )
                        );
                    }
                )
            ),
            topTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final mths = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
                  final idx  = v.toInt();
                  if (idx >= entries.length) return const SizedBox.shrink();
                  final parts = entries[idx].key.split('-');
                  final m = (int.tryParse(parts.last) ?? 1) - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        mths[m], 
                        style: TextStyle(
                            color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                        )
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => isDark ? const Color(0xFF1E293B) : Colors.black87,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 return BarTooltipItem(
                    _formatShortAmount(rod.toY, symbol),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                 );
              }
            )
          )
        ),
      ),
    );
  }
}

// Helper formatting method
String _formatShortAmount(double amount, String symbol) {
  final prefix = symbol.isNotEmpty ? '$symbol ' : '';
  if (amount >= 1000000000) {
    return '$prefix${(amount / 1000000000).toStringAsFixed(1)}B';
  } else if (amount >= 1000000) {
    return '$prefix${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return '$prefix${(amount / 1000).toStringAsFixed(0)}K';
  } else {
    return '$prefix${amount.toStringAsFixed(0)}';
  }
}
