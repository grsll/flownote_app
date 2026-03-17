import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flownote/core/error/failures.dart';
import 'package:flownote/models/wallet_model.dart';
import 'package:uuid/uuid.dart';

/// Wallet repository — manages user accounts/wallets in Firestore.
/// Collection path: users/{uid}/wallets/{walletId}
class WalletRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth      _auth;
  final _uuid = const Uuid();

  WalletRepository({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db   = db   ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _walletsRef =>
      _db.collection('users').doc(_uid).collection('wallets');

  // ── READ ────────────────────────────────────────────────────────────────────

  Future<(Failure?, List<WalletModel>)> getWallets() async {
    try {
      final snapshot = await _walletsRef
          .where('is_archived', isEqualTo: false)
          .orderBy('sort_order')
          .get();
      final wallets = snapshot.docs
          .map((d) => WalletModel.fromJson(d.data(), docId: d.id))
          .toList();
      return (null, wallets);
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal memuat wallet.'), <WalletModel>[]);
    } catch (e) {
      return (ServerFailure(e.toString()), <WalletModel>[]);
    }
  }

  Future<(Failure?, WalletModel?)> getWalletById(String id) async {
    try {
      final doc = await _walletsRef.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return (DatabaseFailure('Wallet tidak ditemukan.'), null);
      }
      return (null, WalletModel.fromJson(doc.data()!, docId: doc.id));
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal memuat wallet.'), null);
    } catch (e) {
      return (ServerFailure(e.toString()), null);
    }
  }

  /// Net worth = sum of all non-excluded wallet balances
  Future<(Failure?, double)> getNetWorth() async {
    try {
      final snapshot = await _walletsRef
          .where('is_archived', isEqualTo: false)
          .where('is_excluded', isEqualTo: false)
          .get();
      final total = snapshot.docs
          .map((d) => (d.data()['balance'] as num?)?.toDouble() ?? 0.0)
          .fold(0.0, (a, b) => a + b);
      return (null, total);
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal menghitung net worth.'), 0.0);
    } catch (e) {
      return (ServerFailure(e.toString()), 0.0);
    }
  }

  // ── CREATE ───────────────────────────────────────────────────────────────────

  Future<(Failure?, WalletModel?)> createWallet(WalletModel wallet) async {
    try {
      final id  = _uuid.v4();
      final now = DateTime.now();
      final model = WalletModel(
        id:             id,
        userId:         _uid,
        name:           wallet.name,
        type:           wallet.type,
        balance:        wallet.initialBalance,
        initialBalance: wallet.initialBalance,
        currency:       wallet.currency,
        colorHex:       wallet.colorHex,
        iconName:       wallet.iconName,
        isExcluded:     wallet.isExcluded,
        sortOrder:      wallet.sortOrder,
        createdAt:      now,
        updatedAt:      now,
      );
      await _walletsRef.doc(id).set(model.toJson());
      return (null, model);
    } on FirebaseException catch (e) {
      return (DatabaseFailure(e.message ?? 'Gagal membuat wallet.'), null);
    } catch (e) {
      return (ServerFailure(e.toString()), null);
    }
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────────

  Future<Failure?> updateWallet(WalletModel wallet) async {
    try {
      final data = wallet.toJson();
      data['updated_at'] = Timestamp.fromDate(DateTime.now());
      await _walletsRef.doc(wallet.id).update(data);
      return null;
    } on FirebaseException catch (e) {
      return DatabaseFailure(e.message ?? 'Gagal memperbarui wallet.');
    } catch (e) {
      return ServerFailure(e.toString());
    }
  }

  /// Adjust wallet balance by [delta] (positive = add, negative = subtract).
  Future<Failure?> adjustBalance(String walletId, double delta) async {
    try {
      await _walletsRef.doc(walletId).update({
        'balance':    FieldValue.increment(delta),
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } on FirebaseException catch (e) {
      return DatabaseFailure(e.message ?? 'Gagal memperbarui saldo.');
    } catch (e) {
      return ServerFailure(e.toString());
    }
  }

  // ── DELETE / ARCHIVE ──────────────────────────────────────────────────────────

  Future<Failure?> archiveWallet(String id) async {
    try {
      await _walletsRef.doc(id).update({
        'is_archived': true,
        'updated_at':  Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } on FirebaseException catch (e) {
      return DatabaseFailure(e.message ?? 'Gagal mengarsip wallet.');
    } catch (e) {
      return ServerFailure(e.toString());
    }
  }
}
