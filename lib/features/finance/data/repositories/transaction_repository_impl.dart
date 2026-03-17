import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flownote/core/error/failures.dart';
import 'package:flownote/features/finance/domain/repositories/transaction_repository.dart';
import 'package:flownote/models/transaction_model.dart';

/// Concrete Firebase implementation of [TransactionRepository].
/// Optimised queries: server-side filtering + Firestore Timestamps.
class TransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth      _auth;

  TransactionRepositoryImpl({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db   = db   ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _txRef =>
      _db.collection('users').doc(_uid).collection('transactions');

  // ── READ ────────────────────────────────────────────────────────────────────

  @override
  Future<(Failure?, List<TransactionModel>)> getTransactions({
    String? walletId,
    String? categoryId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      // Build server-side filtered query to avoid fetching all documents
      Query<Map<String, dynamic>> query = _txRef.orderBy('date', descending: true);

      if (walletId    != null) query = query.where('wallet_id',   isEqualTo: walletId);
      if (categoryId  != null) query = query.where('category_id', isEqualTo: categoryId);
      if (type        != null) query = query.where('type',        isEqualTo: type.value);
      if (startDate   != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate     != null) {
        query = query.where('date', isLessThan: Timestamp.fromDate(endDate));
      }

      query = query.limit(limit);
      final snapshot = await query.get();

      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.data(), docId: doc.id))
          .toList();

      return (null, transactions);
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal memuat transaksi.'), <TransactionModel>[]);
    } catch (e) {
      return (ServerFailure(e.toString()), <TransactionModel>[]);
    }
  }

  // ── SUMMARY ─────────────────────────────────────────────────────────────────

  @override
  Future<(Failure?, Map<String, double>)> getMonthlySummary({
    required int month,
    required int year,
    String? walletId,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate   = DateTime(year, month + 1, 1);

      var query = _txRef
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate));
      if (walletId != null) query = query.where('wallet_id', isEqualTo: walletId);

      final snapshot = await query.get();
      final transactions = snapshot.docs
          .map((d) => TransactionModel.fromJson(d.data(), docId: d.id))
          .toList();

      double income   = 0;
      double expense  = 0;
      for (final t in transactions) {
        if (t.isIncome)  income  += t.amount;
        if (t.isExpense) expense += t.amount;
      }
      return (null, {
        'income':  income,
        'expense': expense,
        'balance': income - expense,
      });
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal memuat ringkasan.'), <String, double>{});
    } catch (e) {
      return (ServerFailure(e.toString()), <String, double>{});
    }
  }

  // ── WEEKLY CHART ─────────────────────────────────────────────────────────────

  @override
  Future<(Failure?, List<Map<String, dynamic>>)> getWeeklyChart({String? walletId}) async {
    try {
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final end   = DateTime(now.year, now.month, now.day + 1);

      var query = _txRef
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
      if (walletId != null) query = query.where('wallet_id', isEqualTo: walletId);

      final snapshot = await query.get();
      final all = snapshot.docs
          .map((d) => TransactionModel.fromJson(d.data(), docId: d.id))
          .toList();

      // Build per-day map for last 7 days
      final Map<String, Map<String, double>> daily = {};
      for (var i = 0; i <= 6; i++) {
        final day = start.add(Duration(days: i));
        final key = _dateKey(day);
        daily[key] = {'income': 0.0, 'expense': 0.0};
      }
      for (final t in all) {
        final key = _dateKey(t.date);
        if (!daily.containsKey(key)) continue;
        if (t.isIncome)  daily[key]!['income']  = daily[key]!['income']!  + t.amount;
        if (t.isExpense) daily[key]!['expense'] = daily[key]!['expense']! + t.amount;
      }
      return (null, daily.entries.map((e) => {'day': e.key, ...e.value}).toList());
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal memuat chart.'), <Map<String, dynamic>>[]);
    } catch (e) {
      return (ServerFailure(e.toString()), <Map<String, dynamic>>[]);
    }
  }

  // ── CREATE ───────────────────────────────────────────────────────────────────

  @override
  Future<(Failure?, TransactionModel?)> createTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final now  = DateTime.now();
      final data = transaction.copyWith().toJson();
      data['created_at'] = Timestamp.fromDate(now);
      data['updated_at'] = Timestamp.fromDate(now);
      data.remove('id');  // let Firestore auto-generate the ID

      final docRef = await _txRef.add(data);
      final created = transaction.copyWith().toJson();
      return (null, TransactionModel.fromJson(created, docId: docRef.id));
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal membuat transaksi.'), null);
    } catch (e) {
      return (ServerFailure(e.toString()), null);
    }
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────────

  @override
  Future<(Failure?, TransactionModel?)> updateTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final data = transaction.toJson();
      data['updated_at'] = Timestamp.fromDate(DateTime.now());
      await _txRef.doc(transaction.id).update(data);
      return (null, transaction);
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal memperbarui transaksi.'), null);
    } catch (e) {
      return (ServerFailure(e.toString()), null);
    }
  }

  // ── DELETE ───────────────────────────────────────────────────────────────────

  @override
  Future<Failure?> deleteTransaction(String id) async {
    try {
      await _txRef.doc(id).delete();
      return null;
    } on FirebaseException catch (e) {
      return DatabaseFailure(e.message ?? 'Gagal menghapus transaksi.');
    } catch (e) {
      return ServerFailure(e.toString());
    }
  }

  // ── SEARCH ───────────────────────────────────────────────────────────────────

  @override
  Future<(Failure?, List<TransactionModel>)> searchTransactions(String query) async {
    try {
      // Firestore doesn't support full-text search natively.
      // We fetch a reasonable ceiling then filter client-side.
      // For production scale, use Algolia or Typesense.
      final snapshot = await _txRef
          .orderBy('date', descending: true)
          .limit(200)
          .get();

      final q = query.toLowerCase();
      final results = snapshot.docs
          .map((d) => TransactionModel.fromJson(d.data(), docId: d.id))
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.note?.toLowerCase().contains(q) ?? false) ||
              (t.categoryName?.toLowerCase().contains(q) ?? false))
          .toList();

      return (null, results);
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal mencari.'), <TransactionModel>[]);
    } catch (e) {
      return (ServerFailure(e.toString()), <TransactionModel>[]);
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
