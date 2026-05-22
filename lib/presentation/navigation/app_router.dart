// lib/presentation/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/role_screen.dart';
import '../donor/donor_dashboard.dart';
import '../ngo/ngo_dashboard.dart';
import '../donor/post_food_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final roleAsync = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final currentPath = state.uri.toString();

      // Not logged in → always go to login
      if (!isLoggedIn) return '/login';

      final role = await ref.read(userRoleProvider.future);

      // No role yet → role selection
      if (role == null) return '/role-select';

      // ← KEY FIX: if already on a valid sub-route, don't redirect
      if (currentPath.startsWith('/donor') ||
          currentPath.startsWith('/post-food')) {
        return null; // let it through
      }
      if (currentPath.startsWith('/ngo')) {
        return null; // let it through
      }

      // Initial routing based on role
      if (role == 'donor') return '/donor';
      if (role == 'ngo') return '/ngo';

      return '/login';
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/donor',
        builder: (context, state) => const DonorDashboard(),
      ),
      GoRoute(
        path: '/ngo',
        builder: (context, state) => const NgoDashboard(),
      ),
      GoRoute(
        path: '/post-food',
        builder: (context, state) => const PostFoodScreen(),
      ),
    ],
  );
});