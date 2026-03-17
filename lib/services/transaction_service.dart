// DEPRECATED — This file is kept for backward compatibility only.
// All new code should use [TransactionRepository] via [transactionRepositoryProvider].
//
// Migration guide:
//   OLD: ref.read(transactionServiceProvider)
//   NEW: ref.read(transactionRepositoryProvider)
//
// This file will be removed in the next major refactor.

@Deprecated('Use TransactionRepository via transactionRepositoryProvider instead.')
export 'package:flownote/features/finance/data/repositories/transaction_repository_impl.dart';
