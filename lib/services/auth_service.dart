// DEPRECATED — This file is kept for backward compatibility only.
// All new code should use [AuthRepository] via [authRepositoryProvider].
//
// Migration guide:
//   OLD: ref.read(authServiceProvider)
//   NEW: ref.read(authRepositoryProvider)
//
// This file will be removed in the next major refactor.

@Deprecated('Use AuthRepository via authRepositoryProvider instead.')
export 'package:flownote/features/authentication/data/repositories/auth_repository_impl.dart';
