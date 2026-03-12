import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flownote/models/transaction_model.dart';

/// Transaction service — menggunakan Firestore
/// Collection: transactions/{uid}/items/{txId}
class TransactionService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _txRef =>
      _db.collection('transactions').doc(_uid).collection('items');

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<List<TransactionModel>> getTransactions({
    String? type,
    String? categoryId,
    String? startDate,
    String? endDate,
    int limit = 100,
  }) async {
    // Ambil semua → filter client side untuk hindari composite index
    final snapshot = await _txRef.orderBy('date', descending: true).limit(limit).get();

    var transactions = snapshot.docs
        .map((doc) => TransactionModel.fromJson(doc.data(), docId: doc.id))
        .toList();

    // Filter di client side — tidak perlu composite index Firestore
    if (type != null) {
      transactions = transactions.where((t) => t.type == type).toList();
    }
    if (categoryId != null) {
      transactions = transactions.where((t) => t.category?.id == categoryId).toList();
    }
    if (startDate != null) {
      final start = DateTime.parse(startDate);
      transactions = transactions.where((t) => !t.date.isBefore(start)).toList();
    }
    if (endDate != null) {
      final end = DateTime.parse(endDate);
      transactions = transactions.where((t) => !t.date.isAfter(end)).toList();
    }

    return transactions;
  }

  // ── SUMMARY ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSummary({int? month, int? year}) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year  ?? now.year;

    // Ambil semua transaksi — filter month di client
    final snapshot = await _txRef.limit(500).get();
    final all = snapshot.docs
        .map((doc) => TransactionModel.fromJson(doc.data(), docId: doc.id))
        .toList();

    // Filter bulan ini
    final monthly = all.where((t) => t.date.month == m && t.date.year == y).toList();

    double totalIncome  = 0;
    double totalExpense = 0;
    for (final t in monthly) {
      if (t.isIncome)  totalIncome  += t.amount;
      if (t.isExpense) totalExpense += t.amount;
    }

    // All time
    double allIncome  = 0;
    double allExpense = 0;
    for (final t in all) {
      if (t.isIncome)  allIncome  += t.amount;
      if (t.isExpense) allExpense += t.amount;
    }

    return {
      'total_income':  totalIncome,
      'total_expense': totalExpense,
      'balance':       totalIncome - totalExpense,
      'allTime': {
        'total_income':  allIncome,
        'total_expense': allExpense,
        'balance':       allIncome - allExpense,
      },
      'count': monthly.length,
    };
  }

  // ── WEEKLY CHART (7 hari terakhir) ────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWeeklyChart() async {
    final now   = DateTime.now();
    final start = now.subtract(const Duration(days: 6));

    final snapshot = await _txRef.limit(300).get();
    final all = snapshot.docs
        .map((doc) => TransactionModel.fromJson(doc.data(), docId: doc.id))
        .toList();

    // Aggregate per hari (7 hari terakhir)
    final Map<String, Map<String, double>> daily = {};
    for (var i = 0; i <= 6; i++) {
      final day = start.add(Duration(days: i));
      final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
      daily[key] = {'income': 0.0, 'expense': 0.0};
    }

    for (final t in all) {
      if (t.date.isBefore(start.subtract(const Duration(days: 1)))) continue;
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2,'0')}-${t.date.day.toString().padLeft(2,'0')}';
      if (!daily.containsKey(key)) continue;
      if (t.isIncome)  daily[key]!['income']  = daily[key]!['income']!  + t.amount;
      if (t.isExpense) daily[key]!['expense'] = daily[key]!['expense']! + t.amount;
    }

    return daily.entries.map((e) => {'day': e.key, ...e.value}).toList();
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  Future<TransactionModel> createTransaction({
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
    final now  = DateTime.now();
    final data = <String, dynamic>{
      'user_id':        _uid,
      'title':          title,
      'amount':         amount,
      'type':           type,
      'date':           date,
      'created_at':     now.toIso8601String(),
    };

    // Tambah optional fields hanya jika tidak null
    if (categoryId    != null) data['category_id']    = categoryId;
    if (categoryName  != null) data['category_name']  = categoryName;
    if (categoryIcon  != null) data['category_icon']  = categoryIcon;
    if (categoryColor != null) data['category_color'] = categoryColor;
    if (note          != null) data['note']           = note;

    final docRef = await _txRef.add(data);
    return TransactionModel.fromJson(data, docId: docRef.id);
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<TransactionModel> updateTransaction(
    String id, {
    required String title,
    required double amount,
    required String type,
    String? categoryId,
    required String date,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'title':  title,
      'amount': amount,
      'type':   type,
      'date':   date,
    };
    if (categoryId != null) data['category_id'] = categoryId;
    if (note       != null) data['note']        = note;

    await _txRef.doc(id).update(data);
    final doc = await _txRef.doc(id).get();
    return TransactionModel.fromJson(doc.data()!, docId: doc.id);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteTransaction(String id) async {
    await _txRef.doc(id).delete();
  }
}
