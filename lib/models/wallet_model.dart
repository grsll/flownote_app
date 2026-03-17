import 'package:cloud_firestore/cloud_firestore.dart';

/// Wallet / Account model
/// Stored at: users/{uid}/wallets/{walletId}
class WalletModel {
  final String id;
  final String userId;
  final String name;
  final WalletType type;
  final double balance;
  final double initialBalance;
  final String currency;
  final String colorHex;
  final String iconName;
  final bool isExcluded;  // exclude from net worth calculation
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.initialBalance,
    this.currency = 'IDR',
    this.colorHex = '#4F46E5',
    this.iconName = 'account_balance_wallet',
    this.isExcluded = false,
    this.isArchived = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return WalletModel(
      id:             docId ?? json['id'] as String? ?? '',
      userId:         json['user_id'] as String? ?? '',
      name:           json['name'] as String? ?? 'Wallet',
      type:           WalletType.fromString(json['type'] as String? ?? 'cash'),
      balance:        (json['balance'] as num?)?.toDouble() ?? 0.0,
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0.0,
      currency:       json['currency'] as String? ?? 'IDR',
      colorHex:       json['color_hex'] as String? ?? '#4F46E5',
      iconName:       json['icon_name'] as String? ?? 'account_balance_wallet',
      isExcluded:     json['is_excluded'] as bool? ?? false,
      isArchived:     json['is_archived'] as bool? ?? false,
      sortOrder:      json['sort_order'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':              id,
    'user_id':         userId,
    'name':            name,
    'type':            type.value,
    'balance':         balance,
    'initial_balance': initialBalance,
    'currency':        currency,
    'color_hex':       colorHex,
    'icon_name':       iconName,
    'is_excluded':     isExcluded,
    'is_archived':     isArchived,
    'sort_order':      sortOrder,
    'created_at':      Timestamp.fromDate(createdAt),
    'updated_at':      Timestamp.fromDate(updatedAt),
  };

  WalletModel copyWith({
    String? name,
    WalletType? type,
    double? balance,
    double? initialBalance,
    String? currency,
    String? colorHex,
    String? iconName,
    bool? isExcluded,
    bool? isArchived,
    int? sortOrder,
  }) {
    return WalletModel(
      id:             id,
      userId:         userId,
      name:           name ?? this.name,
      type:           type ?? this.type,
      balance:        balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      currency:       currency ?? this.currency,
      colorHex:       colorHex ?? this.colorHex,
      iconName:       iconName ?? this.iconName,
      isExcluded:     isExcluded ?? this.isExcluded,
      isArchived:     isArchived ?? this.isArchived,
      sortOrder:      sortOrder ?? this.sortOrder,
      createdAt:      createdAt,
      updatedAt:      DateTime.now(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

enum WalletType {
  cash('cash', 'Tunai'),
  bank('bank', 'Bank'),
  ewallet('ewallet', 'E-Wallet'),
  credit('credit', 'Kartu Kredit'),
  savings('savings', 'Tabungan'),
  investment('investment', 'Investasi');

  const WalletType(this.value, this.label);
  final String value;
  final String label;

  static WalletType fromString(String value) {
    return WalletType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WalletType.cash,
    );
  }
}
