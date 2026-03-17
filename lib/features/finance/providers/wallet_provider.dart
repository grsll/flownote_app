import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/core/error/failures.dart';
import 'package:flownote/core/providers/repository_providers.dart';
import 'package:flownote/features/finance/data/repositories/wallet_repository.dart';
import 'package:flownote/models/wallet_model.dart';

// ── Wallet State ───────────────────────────────────────────────────────────────
class WalletState {
  final List<WalletModel> wallets;
  final double            netWorth;
  final bool              isLoading;
  final Failure?          failure;
  final String?           selectedWalletId;

  const WalletState({
    this.wallets          = const [],
    this.netWorth         = 0.0,
    this.isLoading        = false,
    this.failure,
    this.selectedWalletId,
  });

  String? get errorMessage => failure?.message;

  WalletModel? get selectedWallet => selectedWalletId == null
      ? null
      : wallets.where((w) => w.id == selectedWalletId).firstOrNull;

  WalletState copyWith({
    List<WalletModel>? wallets,
    double?            netWorth,
    bool?              isLoading,
    Failure?           failure,
    bool               clearFailure = false,
    String?            selectedWalletId,
  }) {
    return WalletState(
      wallets:          wallets          ?? this.wallets,
      netWorth:         netWorth         ?? this.netWorth,
      isLoading:        isLoading        ?? this.isLoading,
      failure:          clearFailure ? null : (failure ?? this.failure),
      selectedWalletId: selectedWalletId ?? this.selectedWalletId,
    );
  }
}

// ── Wallet Notifier ────────────────────────────────────────────────────────────
class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repository;

  WalletNotifier(this._repository) : super(const WalletState());

  // ── Load ──────────────────────────────────────────────────────────────────────

  Future<void> loadWallets() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final (failure, wallets) = await _repository.getWallets();
    if (failure != null) {
      state = state.copyWith(isLoading: false, failure: failure);
      return;
    }

    // Calculate net worth from non-excluded wallets
    final netWorth = wallets
        .where((w) => !w.isExcluded)
        .fold(0.0, (sum, w) => sum + w.balance);

    state = state.copyWith(
      isLoading: false,
      wallets:   wallets,
      netWorth:  netWorth,
    );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────────

  Future<bool> createWallet(WalletModel wallet) async {
    final (failure, created) = await _repository.createWallet(wallet);
    if (failure != null) {
      state = state.copyWith(failure: failure);
      return false;
    }
    if (created != null) {
      state = state.copyWith(wallets: [...state.wallets, created]);
      _recalcNetWorth();
    }
    return true;
  }

  Future<bool> updateWallet(WalletModel wallet) async {
    final failure = await _repository.updateWallet(wallet);
    if (failure != null) {
      state = state.copyWith(failure: failure);
      return false;
    }
    final updated = state.wallets.map((w) => w.id == wallet.id ? wallet : w).toList();
    state = state.copyWith(wallets: updated);
    _recalcNetWorth();
    return true;
  }

  Future<bool> archiveWallet(String id) async {
    final failure = await _repository.archiveWallet(id);
    if (failure != null) {
      state = state.copyWith(failure: failure);
      return false;
    }
    final updated = state.wallets.where((w) => w.id != id).toList();
    state = state.copyWith(wallets: updated);
    _recalcNetWorth();
    return true;
  }

  // ── Selection ──────────────────────────────────────────────────────────────────

  void selectWallet(String? id) => state = state.copyWith(selectedWalletId: id);
  void clearSelection()         => selectWallet(null);

  // ── Helpers ────────────────────────────────────────────────────────────────────

  void _recalcNetWorth() {
    final netWorth = state.wallets
        .where((w) => !w.isExcluded)
        .fold(0.0, (sum, w) => sum + w.balance);
    state = state.copyWith(netWorth: netWorth);
  }

  void clearError() => state = state.copyWith(clearFailure: true);
}

// ── Providers ──────────────────────────────────────────────────────────────────

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.watch(walletRepositoryProvider));
});

/// Quick access: list of active wallets
final walletsListProvider = Provider<List<WalletModel>>((ref) {
  return ref.watch(walletProvider).wallets;
});

/// Quick access: total net worth
final netWorthProvider = Provider<double>((ref) {
  return ref.watch(walletProvider).netWorth;
});
