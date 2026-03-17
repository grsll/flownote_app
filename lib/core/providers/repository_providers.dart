import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flownote/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:flownote/features/authentication/domain/repositories/auth_repository.dart';
import 'package:flownote/features/finance/data/repositories/transaction_repository_impl.dart';
import 'package:flownote/features/finance/data/repositories/wallet_repository.dart';
import 'package:flownote/features/finance/domain/repositories/transaction_repository.dart';

// ── Firebase Core Providers ────────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
  name: 'firebaseAuthProvider',
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
  name: 'firestoreProvider',
);

final googleSignInProvider = Provider<GoogleSignIn>(
  (_) => GoogleSignIn(),
  name: 'googleSignInProvider',
);

// ── Repository Providers ───────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    auth:        ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
    db:          ref.watch(firestoreProvider),
  );
}, name: 'authRepositoryProvider');

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    db:   ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
}, name: 'transactionRepositoryProvider');

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(
    db:   ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
}, name: 'walletRepositoryProvider');
