import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/core/error/failures.dart';
import 'package:flownote/core/providers/repository_providers.dart';
import 'package:flownote/features/finance/domain/repositories/transaction_repository.dart';
import 'package:flownote/models/transaction_model.dart';

// ── Transaction State ──────────────────────────────────────────────────────────
class TransactionState {
  final List<TransactionModel>    transactions;
  final Map<String, double>       summary;          // income, expense, balance
  final List<Map<String, dynamic>> chartData;
  final bool     isLoading;
  final Failure? failure;
  // Filters
  final String?           walletFilter;
  final String?           categoryFilter;
  final TransactionType?  typeFilter;
  final DateTime?         startDate;
  final DateTime?         endDate;

  const TransactionState({
    this.transactions   = const [],
    this.summary        = const {},
    this.chartData      = const [],
    this.isLoading      = false,
    this.failure,
    this.walletFilter,
    this.categoryFilter,
    this.typeFilter,
    this.startDate,
    this.endDate,
  });

  String? get errorMessage => failure?.message;

  TransactionState copyWith({
    List<TransactionModel>?    transactions,
    Map<String, double>?       summary,
    List<Map<String, dynamic>>? chartData,
    bool?    isLoading,
    Failure? failure,
    bool     clearFailure = false,
    String?  walletFilter,
    String?  categoryFilter,
    TransactionType? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionState(
      transactions:   transactions   ?? this.transactions,
      summary:        summary        ?? this.summary,
      chartData:      chartData      ?? this.chartData,
      isLoading:      isLoading      ?? this.isLoading,
      failure:        clearFailure ? null : (failure ?? this.failure),
      walletFilter:   walletFilter   ?? this.walletFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      typeFilter:     typeFilter     ?? this.typeFilter,
      startDate:      startDate      ?? this.startDate,
      endDate:        endDate        ?? this.endDate,
    );
  }
}

// ── Transaction Notifier ───────────────────────────────────────────────────────
class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository _repository;

  TransactionNotifier(this._repository) : super(const TransactionState());

  // ── Load ─────────────────────────────────────────────────────────────────────

  Future<void> loadTransactions({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    state = state.copyWith(isLoading: true, clearFailure: true);

    final (failure, transactions) = await _repository.getTransactions(
      walletId:   state.walletFilter,
      categoryId: state.categoryFilter,
      type:       state.typeFilter,
      startDate:  state.startDate,
      endDate:    state.endDate,
    );

    if (failure != null) {
      state = state.copyWith(isLoading: false, failure: failure);
      return;
    }
    state = state.copyWith(isLoading: false, transactions: transactions);
  }

  Future<void> loadSummary({int? month, int? year}) async {
    final now = DateTime.now();
    final (failure, summary) = await _repository.getMonthlySummary(
      month:    month ?? now.month,
      year:     year  ?? now.year,
      walletId: state.walletFilter,
    );
    if (failure == null) {
      state = state.copyWith(summary: summary);
    }
  }

  Future<void> loadChartData() async {
    final (failure, data) = await _repository.getWeeklyChart(
      walletId: state.walletFilter,
    );
    if (failure == null) {
      state = state.copyWith(chartData: data);
    }
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadTransactions(refresh: true),
      loadSummary(),
      loadChartData(),
    ]);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────────

  Future<bool> createTransaction(TransactionModel transaction) async {
    final (failure, created) = await _repository.createTransaction(transaction);
    if (failure != null) {
      state = state.copyWith(failure: failure);
      return false;
    }
    if (created != null) {
      state = state.copyWith(
        transactions: [created, ...state.transactions],
      );
    }
    await Future.wait([loadSummary(), loadChartData()]);
    return true;
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    final (failure, updated) = await _repository.updateTransaction(transaction);
    if (failure != null) {
      state = state.copyWith(failure: failure);
      return false;
    }
    if (updated != null) {
      final newList = state.transactions
          .map((t) => t.id == transaction.id ? updated : t)
          .toList();
      state = state.copyWith(transactions: newList);
    }
    await Future.wait([loadSummary(), loadChartData()]);
    return true;
  }

  Future<bool> deleteTransaction(String id) async {
    final failure = await _repository.deleteTransaction(id);
    if (failure != null) {
      state = state.copyWith(failure: failure);
      return false;
    }
    state = state.copyWith(
      transactions: state.transactions.where((t) => t.id != id).toList(),
    );
    await Future.wait([loadSummary(), loadChartData()]);
    return true;
  }

  // ── Search ─────────────────────────────────────────────────────────────────────

  Future<List<TransactionModel>> search(String query) async {
    if (query.isEmpty) return [];
    final (_, results) = await _repository.searchTransactions(query);
    return results;
  }

  // ── Filters ────────────────────────────────────────────────────────────────────

  void setFilter({
    String? walletId,
    String? categoryId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    state = state.copyWith(
      walletFilter:   walletId,
      categoryFilter: categoryId,
      typeFilter:     type,
      startDate:      startDate,
      endDate:        endDate,
    );
    loadTransactions(refresh: true);
  }

  void clearFilters() {
    state = const TransactionState();
    loadTransactions(refresh: true);
  }

  void clearError() => state = state.copyWith(clearFailure: true);
}

// ── Provider ───────────────────────────────────────────────────────────────────

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref.watch(transactionRepositoryProvider));
});

/// Quick access to current month summary
final monthlySummaryProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(transactionProvider).summary;
});
