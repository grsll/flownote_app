import 'package:flutter/material.dart';

/// Category model for transactions (Firestore)
class CategoryModel {
  final String id;   // Firestore document ID
  final String name;
  final String icon;
  final String color;
  final String type; // income | expense | both
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.isDefault,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CategoryModel(
      id:        docId ?? json['id'] as String? ?? '',
      name:      json['name'] as String,
      icon:      json['icon'] as String? ?? 'category',
      color:     json['color'] as String? ?? '#6366F1',
      type:      json['type'] as String? ?? 'both',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name':       name,
    'icon':       icon,
    'color':      color,
    'type':       type,
    'is_default': isDefault,
  };

  /// Parse hex color string to Flutter Color
  Color get colorValue {
    final hex = color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData get iconData => _iconMap[icon] ?? Icons.category;

  static const _iconMap = <String, IconData>{
    'work':           Icons.work_rounded,
    'laptop':         Icons.laptop_rounded,
    'trending_up':    Icons.trending_up_rounded,
    'card_giftcard':  Icons.card_giftcard_rounded,
    'attach_money':   Icons.attach_money_rounded,
    'restaurant':     Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_rounded,
    'shopping_bag':   Icons.shopping_bag_rounded,
    'receipt':        Icons.receipt_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'school':         Icons.school_rounded,
    'movie':          Icons.movie_rounded,
    'home':           Icons.home_rounded,
    'savings':        Icons.savings_rounded,
    'more_horiz':     Icons.more_horiz_rounded,
    'category':       Icons.category_rounded,
  };
}
