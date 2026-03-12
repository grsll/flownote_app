import 'package:flownote/models/category_model.dart';

/// Transaction model — income or expense entry (Firestore)
class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String type; // income | expense
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.date,
    this.note,
    required this.createdAt,
  });

  bool get isIncome  => type == 'income';
  bool get isExpense => type == 'expense';

  factory TransactionModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return TransactionModel(
      id:            docId ?? json['id'] as String? ?? '',
      userId:        json['user_id'] as String? ?? '',
      title:         json['title'] as String,
      amount:        double.parse(json['amount'].toString()),
      type:          json['type'] as String,
      categoryId:    json['category_id'] as String?,
      categoryName:  json['category_name'] as String?,
      categoryIcon:  json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
      date: json['date'] is String
          ? DateTime.parse(json['date'] as String)
          : (json['date'] as dynamic)?.toDate() ?? DateTime.now(),
      note:          json['note'] as String?,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id':       userId,
    'title':         title,
    'amount':        amount,
    'type':          type,
    'category_id':   categoryId,
    'category_name': categoryName,
    'category_icon': categoryIcon,
    'category_color':categoryColor,
    'date':          date.toIso8601String().split('T')[0],
    'note':          note,
    'created_at':    createdAt.toIso8601String(),
  };

  /// Build synthetic CategoryModel from embedded fields
  CategoryModel? get category {
    if (categoryId == null) return null;
    return CategoryModel(
      id:        categoryId!,
      name:      categoryName ?? 'Other',
      icon:      categoryIcon ?? 'category',
      color:     categoryColor ?? '#6366F1',
      type:      type,
      isDefault: false,
    );
  }
}
