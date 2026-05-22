// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Watches auth state changes (login / logout)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

// Fetches user role — re-runs whenever auth state changes
final userRoleProvider = FutureProvider<String?>((ref) async {
  // ← Watch auth state so this re-runs on account switch
  final authState = ref.watch(authStateProvider);

  // If not logged in, return null immediately
  final userId = authState.valueOrNull?.session?.user.id;
  if (userId == null) return null;

  final data = await supabase
      .from('users')
      .select('role')
      .eq('id', userId)
      .maybeSingle();

  return data?['role'] as String?;
});