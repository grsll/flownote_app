import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flownote/models/category_model.dart';

/// Category service — menggunakan Firestore
/// Collection: categories/{uid}/items/{catId}
class CategoryService {
  final FirebaseFirestore _db   = FirebaseFirestore.instance;
  final FirebaseAuth      _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _catRef =>
      _db.collection('categories').doc(_uid).collection('items');

  // ── Default categories ────────────────────────────────────────────────────
  static const _defaultCategories = [
    {'name': 'Gaji',         'icon': 'attach_money',   'color': '#10B981', 'type': 'income',  'is_default': true, 'order': 1},
    {'name': 'Freelance',    'icon': 'laptop',          'color': '#6366F1', 'type': 'income',  'is_default': true, 'order': 2},
    {'name': 'Investasi',    'icon': 'trending_up',     'color': '#F59E0B', 'type': 'income',  'is_default': true, 'order': 3},
    {'name': 'Hadiah',       'icon': 'card_giftcard',   'color': '#EC4899', 'type': 'income',  'is_default': true, 'order': 4},
    {'name': 'Makan',        'icon': 'restaurant',      'color': '#EF4444', 'type': 'expense', 'is_default': true, 'order': 5},
    {'name': 'Transport',    'icon': 'directions_car',  'color': '#F97316', 'type': 'expense', 'is_default': true, 'order': 6},
    {'name': 'Belanja',      'icon': 'shopping_bag',    'color': '#8B5CF6', 'type': 'expense', 'is_default': true, 'order': 7},
    {'name': 'Tagihan',      'icon': 'receipt',         'color': '#64748B', 'type': 'expense', 'is_default': true, 'order': 8},
    {'name': 'Kesehatan',    'icon': 'local_hospital',  'color': '#06B6D4', 'type': 'expense', 'is_default': true, 'order': 9},
    {'name': 'Pendidikan',   'icon': 'school',          'color': '#7C3AED', 'type': 'expense', 'is_default': true, 'order': 10},
    {'name': 'Hiburan',      'icon': 'movie',           'color': '#D946EF', 'type': 'expense', 'is_default': true, 'order': 11},
    {'name': 'Rumah',        'icon': 'home',            'color': '#14B8A6', 'type': 'expense', 'is_default': true, 'order': 12},
    {'name': 'Tabungan',     'icon': 'savings',         'color': '#22C55E', 'type': 'both',    'is_default': true, 'order': 13},
    {'name': 'Lainnya',      'icon': 'more_horiz',      'color': '#94A3B8', 'type': 'both',    'is_default': true, 'order': 14},
  ];

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories() async {
    // Query tanpa orderBy — aman tanpa composite index
    final snapshot = await _catRef.get();

    if (snapshot.docs.isEmpty) {
      // User baru — seed kategori default dulu
      await _seedDefaultCategories();
      // Ambil lagi setelah seed
      final seeded = await _catRef.get();
      return _docsToModels(seeded);
    }

    return _docsToModels(snapshot);
  }

  List<CategoryModel> _docsToModels(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs
        .map((doc) => CategoryModel.fromJson(doc.data(), docId: doc.id))
        .toList();
    // Sort client-side: income dulu, expense, both; dalam setiap grup urutkan nama
    list.sort((a, b) {
      const order = ['income', 'expense', 'both'];
      final cmp = order.indexOf(a.type).compareTo(order.indexOf(b.type));
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  Future<CategoryModel> createCategory({
    required String name,
    String icon  = 'category',
    String color = '#6366F1',
    String type  = 'both',
  }) async {
    final data = {
      'name':       name,
      'icon':       icon,
      'color':      color,
      'type':       type,
      'is_default': false,
    };
    final docRef = await _catRef.add(data);
    return CategoryModel.fromJson(data, docId: docRef.id);
  }

  // ── SEED defaults ─────────────────────────────────────────────────────────

  Future<void> _seedDefaultCategories() async {
    final batch = _db.batch();
    for (final cat in _defaultCategories) {
      final ref = _catRef.doc();
      batch.set(ref, Map<String, dynamic>.from(cat));
    }
    await batch.commit();
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteCategory(String id) async {
    await _catRef.doc(id).delete();
  }
}
