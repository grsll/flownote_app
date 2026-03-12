import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/core/theme/app_theme.dart';
import 'package:flownote/features/dashboard/screens/dashboard_screen.dart';
import 'package:flownote/features/finance/screens/finance_screen.dart';
import 'package:flownote/features/notes/screens/notes_screen.dart';
import 'package:flownote/features/analytics/screens/analytics_screen.dart';
import 'package:flownote/features/finance/screens/add_transaction_screen.dart';
import 'package:flownote/features/notes/screens/add_note_screen.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  static const _screens = [
    DashboardScreen(),
    FinanceScreen(),
    NotesScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index  = ref.watch(navIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: index, children: _screens),

        // FAB — visible only on Dashboard, Finance, Notes tabs
        floatingActionButton: index < 3
            ? _GradientFab(
                key: ValueKey(index),
                onTap: () => index == 2
                    ? _showAddNote(context, ref)
                    : _showAddTransaction(context, ref),
                icon: index == 2 ? Icons.edit_rounded : Icons.add_rounded,
              )
            : null,

        bottomNavigationBar: _FloatingNavBar(index: index, ref: ref, isDark: isDark),
      ),
    );
  }

  void _showAddTransaction(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  void _showAddNote(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddNoteSheet(),
    );
  }
}

// ── Floating Nav Bar ──────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int index;
  final WidgetRef ref;
  final bool isDark;

  const _FloatingNavBar({
    required this.index,
    required this.ref,
    required this.isDark,
  });

  static const _items = [
    _NavData(icon: Icons.home_rounded,                    outlinedIcon: Icons.home_outlined,                    label: 'Beranda'),
    _NavData(icon: Icons.account_balance_wallet_rounded,  outlinedIcon: Icons.account_balance_wallet_outlined,  label: 'Keuangan'),
    _NavData(icon: Icons.sticky_note_2_rounded,           outlinedIcon: Icons.sticky_note_2_outlined,           label: 'Catatan'),
    _NavData(icon: Icons.bar_chart_rounded,               outlinedIcon: Icons.bar_chart_outlined,               label: 'Analitik'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item     = _items[i];
              final selected = index == i;
              return Expanded(
                child: _NavPill(
                  icon:        item.icon,
                  outlinedIcon: item.outlinedIcon,
                  label:       item.label,
                  selected:    selected,
                  isDark:      isDark,
                  onTap:       () => ref.read(navIndexProvider.notifier).state = i,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  const _NavData({required this.icon, required this.outlinedIcon, required this.label});
}

class _NavPill extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavPill({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? icon : outlinedIcon,
                key: ValueKey(selected),
                color: selected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextSec : AppColors.textHint),
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextSec : AppColors.textHint),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient FAB ──────────────────────────────────────────────────────────────
class _GradientFab extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _GradientFab({super.key, required this.onTap, required this.icon});

  @override
  State<_GradientFab> createState() => _GradientFabState();
}

class _GradientFabState extends State<_GradientFab> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // Entrance animation
    _ctrl.forward().then((_) => _ctrl.reverse());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
