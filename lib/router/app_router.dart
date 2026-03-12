import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flownote/features/auth/providers/auth_provider.dart';
import 'package:flownote/features/auth/screens/splash_screen.dart';
import 'package:flownote/features/auth/screens/login_screen.dart';
import 'package:flownote/features/auth/screens/register_screen.dart';
import 'package:flownote/features/dashboard/screens/main_scaffold.dart';
import 'package:flownote/features/profile/screens/profile_screen.dart';
import 'package:flownote/features/analytics/screens/analytics_screen.dart';

// Shell navigator key
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final status = ref.watch(authProvider.select((state) => state.status));

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (status == AuthStatus.unknown) return '/splash';
      
      if (status == AuthStatus.unauthenticated) {
        if (!['/login', '/register'].contains(location)) {
          return '/login';
        }
      }
      
      if (status == AuthStatus.authenticated) {
        if (['/login', '/register', '/splash'].contains(location)) {
          return '/';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash',   builder: (ctx, _) => const SplashScreen()),
      GoRoute(path: '/login',    builder: (ctx, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, _) => const RegisterScreen()),
      GoRoute(path: '/',         builder: (ctx, _) => const MainScaffold()),
      GoRoute(path: '/profile',  builder: (ctx, _) => const ProfileScreen()),
      GoRoute(path: '/analytics',builder: (ctx, _) => const AnalyticsScreen()),
    ],
  );
});
