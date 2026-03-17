import 'package:flownote/core/error/failures.dart';
import 'package:flownote/models/transaction_model.dart';

/// Abstract interface for transaction data operations.
abstract interface class TransactionRepository {
  /// Fetch recent transactions for the current user.
  Future<(Failure?, List<TransactionModel>)> getTransactions({
    String? walletId,
    String? categoryId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit,
  });

  /// Fetch monthly summary: income, expense, balance.
  Future<(Failure?, Map<String, double>)> getMonthlySummary({
    required int month,
    required int year,
    String? walletId,
  });

  /// Fetch last 7 days chart data.
  Future<(Failure?, List<Map<String, dynamic>>)> getWeeklyChart({String? walletId});

  /// Create a new transaction and update wallet balance.
  Future<(Failure?, TransactionModel?)> createTransaction(TransactionModel transaction);

  /// Update an existing transaction.
  Future<(Failure?, TransactionModel?)> updateTransaction(TransactionModel transaction);

  /// Delete a transaction by ID.
  Future<Failure?> deleteTransaction(String id);

  /// Search transactions by title keyword.
  Future<(Failure?, List<TransactionModel>)> searchTransactions(String query);
}
