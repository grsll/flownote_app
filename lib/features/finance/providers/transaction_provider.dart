import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/models/transaction_model.dart';
import 'package:flownote/services/transaction_service.dart';

// ── Transaction State ─────────────────────────────────────────────────────────
class TransactionState {
  final List<TransactionModel>    transactions;
  final Map<String, dynamic>?     summary;
  final List<Map<String, dynamic>> chartData;
  final bool     isLoading;
  final String?  error;
  final String?  typeFilter;     // income | expense | null
  final String?  categoryFilter; // Firestore String ID

  const TransactionState({
    this.transactions   = const [],
    this.summary,
    this.chartData      = const [],
    this.isLoading      = false,
    this.error,
    this.typeFilter,
    this.categoryFilter,
  });

  TransactionState copyWith({
    List<TransactionModel>?     transactions,
    Map<String, dynamic>?       summary,
    List<Map<String, dynamic>>? chartData,
    bool?    isLoading,
    String?  error,
    String?  typeFilter,
    String?  categoryFilter,
  }) {
    return TransactionState(
      transactions:   transactions   ?? this.transactions,
      summary:        summary        ?? this.summary,
      chartData:      chartData      ?? this.chartData,
      isLoading:      isLoading      ?? this.isLoading,
      error:          error,
      typeFilter:     typeFilter     ?? this.typeFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }
}

// ── Transaction Notifier ──────────────────────────────────────────────────────
class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionService _service;
  TransactionNotifier(this._service) : super(const TransactionState());

  Future<void> loadTransactions({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.getTransactions(
        type: state.typeFilter,
        categoryId: state.categoryFilter,
      );
      state = state.copyWith(isLoading: false, transactions: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadSummary({int? month, int? year}) async {
    try {
      final result = await _service.getSummary(month: month, year: year);
      state = state.copyWith(summary: result);
    } catch (_) {}
  }

  Future<void> loadChartData() async {
    try {
      final result = await _service.getWeeklyChart();
      state = state.copyWith(chartData: result);
    } catch (_) {}
  }

  Future<bool> createTransaction({
    required String title,
    required double amount,
    required String type,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    required String date,
    String? note,
  }) async {
    try {
      await _service.createTransaction(
        title: title, amount: amount, type: type,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        categoryColor: categoryColor,
        date: date, note: note,
      );
      await loadTransactions(refresh: true);
      await loadSummary();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _service.deleteTransaction(id);
      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      );
      await loadSummary();
      return true;
    } catch (e) {
      return false;
    }
  }

  void setFilter({String? type, String? categoryId}) {
    state = state.copyWith(typeFilter: type, categoryFilter: categoryId);
    loadTransactions(refresh: true);
  }

  void clearFilter() {
    state = const TransactionState();
    loadTransactions(refresh: true);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final transactionServiceProvider =
    Provider<TransactionService>((ref) => TransactionService());

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref.read(transactionServiceProvider));
});
