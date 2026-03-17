import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flownote/models/category_model.dart';

/// Transaction model — income, expense or transfer entry
/// Stored at: users/{uid}/transactions/{txId}
class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final String? walletId;
  final String? toWalletId;       // For transfers
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final List<String> tagIds;
  final DateTime date;
  final String? note;
  // Recurring
  final bool isRecurring;
  final String? recurringId;
  final RecurringFrequency? recurringFreq;
  // Metadata
  final String? receiptImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    this.walletId,
    this.toWalletId,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.tagIds = const [],
    required this.date,
    this.note,
    this.isRecurring = false,
    this.recurringId,
    this.recurringFreq,
    this.receiptImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isIncome   => type == TransactionType.income;
  bool get isExpense  => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;

  factory TransactionModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return TransactionModel(
      id:             docId ?? json['id'] as String? ?? '',
      userId:         json['user_id'] as String? ?? '',
      title:          json['title'] as String? ?? '',
      amount:         (json['amount'] as num?)?.toDouble() ?? 0.0,
      type:           TransactionType.fromString(json['type'] as String? ?? 'expense'),
      walletId:       json['wallet_id'] as String?,
      toWalletId:     json['to_wallet_id'] as String?,
      categoryId:     json['category_id'] as String?,
      categoryName:   json['category_name'] as String?,
      categoryIcon:   json['category_icon'] as String?,
      categoryColor:  json['category_color'] as String?,
      tagIds:         (json['tag_ids'] as List<dynamic>?)?.cast<String>() ?? [],
      date:           _parseDate(json['date']),
      note:           json['note'] as String?,
      isRecurring:    json['is_recurring'] as bool? ?? false,
      recurringId:    json['recurring_id'] as String?,
      recurringFreq:  json['recurring_freq'] != null
          ? RecurringFrequency.fromString(json['recurring_freq'] as String)
          : null,
      receiptImageUrl: json['receipt_image_url'] as String?,
      createdAt:      _parseDate(json['created_at']),
      updatedAt:      _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id':           userId,
    'title':             title,
    'amount':            amount,
    'type':              type.value,
    'wallet_id':         walletId,
    'to_wallet_id':      toWalletId,
    'category_id':       categoryId,
    'category_name':     categoryName,
    'category_icon':     categoryIcon,
    'category_color':    categoryColor,
    'tag_ids':           tagIds,
    'date':              Timestamp.fromDate(date),
    'note':              note,
    'is_recurring':      isRecurring,
    'recurring_id':      recurringId,
    'recurring_freq':    recurringFreq?.value,
    'receipt_image_url': receiptImageUrl,
    'created_at':        Timestamp.fromDate(createdAt),
    'updated_at':        Timestamp.fromDate(updatedAt),
  };

  TransactionModel copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? walletId,
    String? toWalletId,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    List<String>? tagIds,
    DateTime? date,
    String? note,
    bool? isRecurring,
    String? recurringId,
    RecurringFrequency? recurringFreq,
    String? receiptImageUrl,
  }) {
    return TransactionModel(
      id:              id,
      userId:          userId,
      title:           title ?? this.title,
      amount:          amount ?? this.amount,
      type:            type ?? this.type,
      walletId:        walletId ?? this.walletId,
      toWalletId:      toWalletId ?? this.toWalletId,
      categoryId:      categoryId ?? this.categoryId,
      categoryName:    categoryName ?? this.categoryName,
      categoryIcon:    categoryIcon ?? this.categoryIcon,
      categoryColor:   categoryColor ?? this.categoryColor,
      tagIds:          tagIds ?? this.tagIds,
      date:            date ?? this.date,
      note:            note ?? this.note,
      isRecurring:     isRecurring ?? this.isRecurring,
      recurringId:     recurringId ?? this.recurringId,
      recurringFreq:   recurringFreq ?? this.recurringFreq,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      createdAt:       createdAt,
      updatedAt:       DateTime.now(),
    );
  }

  /// Build synthetic CategoryModel from embedded fields
  CategoryModel? get category {
    if (categoryId == null) return null;
    return CategoryModel(
      id:        categoryId!,
      name:      categoryName ?? 'Other',
      icon:      categoryIcon ?? 'category',
      color:     categoryColor ?? '#6366F1',
      type:      type.value,
      isDefault: false,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

// ── Enums ──────────────────────────────────────────────────────────────────────

enum TransactionType {
  income('income'),
  expense('expense'),
  transfer('transfer');

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.expense,
    );
  }
}

enum RecurringFrequency {
  daily('daily',     'Setiap Hari'),
  weekly('weekly',   'Setiap Minggu'),
  monthly('monthly', 'Setiap Bulan'),
  yearly('yearly',   'Setiap Tahun');

  const RecurringFrequency(this.value, this.label);
  final String value;
  final String label;

  static RecurringFrequency fromString(String value) {
    return RecurringFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecurringFrequency.monthly,
    );
  }
}
