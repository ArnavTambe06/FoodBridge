// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/navigation/app_router.dart';
import 'core/widgets/offline_banner.dart';
import 'core/theme/app_theme.dart';

class FoodBridgeApp extends ConsumerWidget {
  const FoodBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FoodBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme, // ← use new theme
      routerConfig: router,
      builder: (context, child) {
        return Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child ?? const SizedBox()),
          ],
        );
      },
    );
  }
}