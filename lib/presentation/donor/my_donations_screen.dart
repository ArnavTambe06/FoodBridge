// lib/presentation/donor/my_donations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/food.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cache_service.dart';
import '../../core/utils/error_handler.dart';
import 'donation_detail_screen.dart';

final myDonationsProvider = FutureProvider<List<Food>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;
  try {
    final data = await supabase
        .from('foods')
        .select()
        .eq('donor_id', userId)
        .order('created_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(data);
    await CacheService.saveMyDonations(list);
    return list.map((e) => Food.fromJson(e)).toList();
  } catch (e) {
    final cached = await CacheService.loadMyDonations();
    if (cached != null && cached.isNotEmpty) {
      return cached.map((e) => Food.fromJson(e)).toList();
    }
    rethrow;
  }
});

class MyDonationsScreen extends ConsumerWidget {
  const MyDonationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(myDonationsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'My Donations',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => ref.refresh(myDonationsProvider),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                ),
              ),
            ],
          ),

          // Stats row
          SliverToBoxAdapter(
            child: donationsAsync.maybeWhen(
              data: (foods) => _buildStatsRow(foods),
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          // Content
          donationsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: _ShimmerDonationList(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: _buildErrorState(
                  ErrorHandler.parseError(e),
                      () => ref.refresh(myDonationsProvider)),
            ),
            data: (foods) => foods.isEmpty
                ? SliverFillRemaining(
              child: _buildEmptyState(),
            )
                : SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  24, 8, 24, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                    padding:
                    const EdgeInsets.only(bottom: 14),
                    child: _DonationCard(
                        food: foods[index]),
                  ),
                  childCount: foods.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<Food> foods) {
    final available =
        foods.where((f) => f.status == 'available').length;
    final reserved =
        foods.where((f) => f.status == 'reserved').length;
    final completed =
        foods.where((f) => f.status == 'completed').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          _statChip('${foods.length}', 'Total',
              AppColors.surfaceContainerLow, AppColors.onSurface),
          const SizedBox(width: 8),
          _statChip('$available', 'Active',
              AppColors.primaryFixed.withOpacity(0.5),
              AppColors.primary),
          const SizedBox(width: 8),
          _statChip('$reserved', 'Reserved',
              AppColors.secondaryContainer.withOpacity(0.4),
              AppColors.secondary),
          const SizedBox(width: 8),
          _statChip('$completed', 'Done',
              AppColors.surfaceContainerHighest,
              AppColors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _statChip(
      String value, String label, Color bg, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No donations yet',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your food donations will appear here.\nTap + Post Food to get started.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildErrorState(String message, VoidCallback onRetry) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.error_outline_rounded,
                    color: Colors.red[400], size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryContainer
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Donation Card ─────────────────────────────────────────────────────────────

class _DonationCard extends StatelessWidget {
  final Food food;

  const _DonationCard({required this.food});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (food.status) {
      'available' => AppColors.primary,
      'reserved' => AppColors.secondary,
      'completed' => AppColors.onSurfaceVariant,
      _ => AppColors.onSurfaceVariant,
    };

    final statusBg = switch (food.status) {
      'available' => AppColors.primaryFixed.withOpacity(0.5),
      'reserved' =>
          AppColors.secondaryContainer.withOpacity(0.4),
      'completed' => AppColors.surfaceContainerHighest,
      _ => AppColors.surfaceContainerHighest,
    };

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DonationDetailScreen(food: food)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: food.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: food.imageUrls.first,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) =>
                    _placeholder(),
              )
                  : _placeholder(),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        food.status[0].toUpperCase() +
                            food.status.substring(1),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      food.foodName,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      food.quantity,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 12,
                            color: AppColors.onSurfaceVariant
                                .withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          _formatExpiry(food.expiryTime),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant.withOpacity(0.4),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 110,
    height: 110,
    color: AppColors.surfaceContainerLow,
    child: Icon(
      Icons.fastfood_outlined,
      color: AppColors.onSurfaceVariant.withOpacity(0.4),
      size: 32,
    ),
  );

  String _formatExpiry(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours < 1) return 'Expires in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Expires in ${diff.inHours}h';
    return 'Expires ${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ShimmerDonationList extends StatelessWidget {
  const _ShimmerDonationList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        children: List.generate(
          4,
              (_) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}