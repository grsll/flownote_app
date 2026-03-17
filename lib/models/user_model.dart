import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User model — mapped from Firebase Auth + Firestore profile
/// Stored at: users/{uid}
class UserModel {
  final String id;         // Firebase UID
  final String name;
  final String email;
  final String? avatarUrl;
  final String currency;          // e.g. 'IDR', 'USD'
  final String language;          // e.g. 'id', 'en'
  final String? defaultWalletId;
  final bool isPremium;
  final UserSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.currency = 'IDR',
    this.language = 'id',
    this.defaultWalletId,
    this.isPremium = false,
    this.settings = const UserSettings(),
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firebase Auth User (first-time sign-in)
  factory UserModel.fromFirebase(User user) {
    final now = DateTime.now();
    return UserModel(
      id:        user.uid,
      name:      user.displayName ?? user.email?.split('@').first ?? 'User',
      email:     user.email ?? '',
      avatarUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? now,
      updatedAt: now,
    );
  }

  /// Create from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:              json['id'] as String? ?? '',
      name:            json['name'] as String? ?? 'User',
      email:           json['email'] as String? ?? '',
      avatarUrl:       json['avatar_url'] as String?,
      currency:        json['currency'] as String? ?? 'IDR',
      language:        json['language'] as String? ?? 'id',
      defaultWalletId: json['default_wallet_id'] as String?,
      isPremium:       json['is_premium'] as bool? ?? false,
      settings: json['settings'] != null
          ? UserSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const UserSettings(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                id,
    'name':              name,
    'email':             email,
    'avatar_url':        avatarUrl,
    'currency':          currency,
    'language':          language,
    'default_wallet_id': defaultWalletId,
    'is_premium':        isPremium,
    'settings':          settings.toJson(),
    'created_at':        Timestamp.fromDate(createdAt),
    'updated_at':        Timestamp.fromDate(updatedAt),
  };

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? currency,
    String? language,
    String? defaultWalletId,
    bool? isPremium,
    UserSettings? settings,
  }) {
    return UserModel(
      id:              id,
      name:            name ?? this.name,
      email:           email,
      avatarUrl:       avatarUrl ?? this.avatarUrl,
      currency:        currency ?? this.currency,
      language:        language ?? this.language,
      defaultWalletId: defaultWalletId ?? this.defaultWalletId,
      isPremium:       isPremium ?? this.isPremium,
      settings:        settings ?? this.settings,
      createdAt:       createdAt,
      updatedAt:       DateTime.now(),
    );
  }

  /// User initials (for avatar placeholder)
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

// ── User Settings (nested object) ─────────────────────────────────────────────

class UserSettings {
  final bool notificationsEnabled;
  final int billReminderDaysBefore;
  final bool biometricEnabled;
  final bool pinEnabled;
  final int startOfMonth;          // day of month budgets restart (1, 15, 25)
  final bool hideBalance;          // privacy mode

  const UserSettings({
    this.notificationsEnabled  = true,
    this.billReminderDaysBefore = 3,
    this.biometricEnabled      = false,
    this.pinEnabled            = false,
    this.startOfMonth          = 1,
    this.hideBalance           = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      notificationsEnabled:   json['notifications_enabled'] as bool? ?? true,
      billReminderDaysBefore: json['bill_reminder_days'] as int? ?? 3,
      biometricEnabled:       json['biometric_enabled'] as bool? ?? false,
      pinEnabled:             json['pin_enabled'] as bool? ?? false,
      startOfMonth:           json['start_of_month'] as int? ?? 1,
      hideBalance:            json['hide_balance'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'notifications_enabled': notificationsEnabled,
    'bill_reminder_days':    billReminderDaysBefore,
    'biometric_enabled':     biometricEnabled,
    'pin_enabled':           pinEnabled,
    'start_of_month':        startOfMonth,
    'hide_balance':          hideBalance,
  };

  UserSettings copyWith({
    bool? notificationsEnabled,
    int? billReminderDaysBefore,
    bool? biometricEnabled,
    bool? pinEnabled,
    int? startOfMonth,
    bool? hideBalance,
  }) {
    return UserSettings(
      notificationsEnabled:   notificationsEnabled   ?? this.notificationsEnabled,
      billReminderDaysBefore: billReminderDaysBefore ?? this.billReminderDaysBefore,
      biometricEnabled:       biometricEnabled       ?? this.biometricEnabled,
      pinEnabled:             pinEnabled             ?? this.pinEnabled,
      startOfMonth:           startOfMonth           ?? this.startOfMonth,
      hideBalance:            hideBalance            ?? this.hideBalance,
    );
  }
}
