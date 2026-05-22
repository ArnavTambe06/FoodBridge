import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cache_service.dart';
import '../common/about_screen.dart';
import 'my_donations_screen.dart';
import 'requests_screen.dart';

class DonorDashboard extends ConsumerStatefulWidget {
  const DonorDashboard({super.key});

  @override
  ConsumerState<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends ConsumerState<DonorDashboard> {
  int _currentIndex = 0;

  void _switchTab(int index) => setState(() => _currentIndex = index);

  List<Widget> get _screens => [
    _HomeTab(onSwitchTab: _switchTab),
    const MyDonationsScreen(),
    const RequestsScreen(),
    _ProfileTab(onSwitchTab: _switchTab),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _screens[_currentIndex],
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? GestureDetector(
        onTap: () => context.push('/post-food'),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Post Food',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
          _navItem(1, Icons.volunteer_activism_rounded,
              Icons.volunteer_activism_outlined, 'Donations'),
          _navItem(2, Icons.inbox_rounded, Icons.inbox_outlined, 'Requests'),
          _navItem(3, Icons.person_rounded,
              Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(
      int index, IconData active, IconData inactive, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryFixed.withOpacity(0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? active : inactive,
                color: isActive
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  final void Function(int) onSwitchTab;

  const _HomeTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Donor';
    final firstName = name.split(' ').first;
    final donationsAsync = ref.watch(myDonationsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_greeting()},',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        firstName,
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onSwitchTab(3),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryContainer
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        firstName[0].toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: donationsAsync.when(
              loading: () => _buildImpactBanner(0, 0),
              error: (_, __) => _buildImpactBanner(0, 0),
              data: (foods) {
                final total = foods.length;
                final active =
                    foods.where((f) => f.status == 'available').length;
                return _buildImpactBanner(total, active);
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _QuickActionCard(
                      icon: Icons.add_circle_rounded,
                      label: 'Post\nFood',
                      color: AppColors.primary,
                      bgColor: AppColors.primaryFixed.withOpacity(0.5),
                      onTap: () => context.push('/post-food'),
                    ),
                    const SizedBox(width: 12),
                    _QuickActionCard(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'My\nDonations',
                      color: AppColors.primary,
                      bgColor: AppColors.surfaceContainerLow,
                      onTap: () => onSwitchTab(1), // ← wired
                    ),
                    const SizedBox(width: 12),
                    _QuickActionCard(
                      icon: Icons.inbox_rounded,
                      label: 'Pickup\nRequests',
                      color: AppColors.secondary,
                      bgColor:
                      AppColors.secondaryContainer.withOpacity(0.4),
                      onTap: () => onSwitchTab(2), // ← wired
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Donations',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () => onSwitchTab(1), // ← wired
                  child: Text(
                    'See all',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        donationsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _ShimmerRecent(),
            ),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Could not load donations',
                  style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant)),
            ),
          ),
          data: (foods) => foods.isEmpty
              ? SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.volunteer_activism_outlined,
                        size: 40,
                        color: AppColors.onSurfaceVariant
                            .withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No donations yet',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + Post Food to make your first donation',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (index >= foods.take(3).length) return null;
                return Padding(
                  padding:
                  const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: _RecentDonationTile(food: foods[index]),
                );
              },
              childCount: foods.take(3).length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildImpactBanner(int total, int active) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Impact',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$total Meals\nDonated',
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$active active now',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

// ── Quick Action Card ─────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent Donation Tile ──────────────────────────────────────────────────────

class _RecentDonationTile extends StatelessWidget {
  final dynamic food;

  const _RecentDonationTile({required this.food});

  @override
  Widget build(BuildContext context) {
    final color = switch (food.status) {
      'available' => AppColors.primary,
      'reserved' => AppColors.secondary,
      'completed' => AppColors.onSurfaceVariant,
      _ => AppColors.onSurfaceVariant,
    };
    final bgColor = switch (food.status) {
      'available' => AppColors.primaryFixed.withOpacity(0.4),
      'reserved' => AppColors.secondaryContainer.withOpacity(0.4),
      'completed' => AppColors.surfaceContainerHighest,
      _ => AppColors.surfaceContainerHighest,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: food.imageUrls.isNotEmpty
                ? Image.network(
              food.imageUrls.first,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.foodName,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  food.quantity,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              food.status[0].toUpperCase() + food.status.substring(1),
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.fastfood_outlined,
        color: AppColors.onSurfaceVariant.withOpacity(0.5), size: 24),
  );
}

// ── Shimmer Recent ────────────────────────────────────────────────────────────

class _ShimmerRecent extends StatelessWidget {
  const _ShimmerRecent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
            (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final void Function(int) onSwitchTab;

  const _ProfileTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Donor';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
            child: Text(
              'Profile',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // Profile card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Donor',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Menu items
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
              child: Column(
                children: [
                  _profileMenuItem(
                    Icons.volunteer_activism_rounded,
                    'My Donations',
                    'View all your food donations',
                    AppColors.primaryFixed.withOpacity(0.6),
                    AppColors.primary,
                        () => onSwitchTab(1), // ← wired to tab
                  ),
                  _divider(),
                  _profileMenuItem(
                    Icons.inbox_rounded,
                    'Pickup Requests',
                    'Manage NGO pickup requests',
                    AppColors.secondaryContainer.withOpacity(0.5),
                    AppColors.secondary,
                        () => onSwitchTab(2), // ← wired to tab
                  ),
                  _divider(),
                  _profileMenuItem(
                    Icons.info_outline_rounded,
                    'About FoodBridge',
                    'Learn more about our mission',
                    AppColors.surfaceContainerHigh,
                    AppColors.onSurfaceVariant,
                        () => Navigator.push(          // ← wired
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AboutScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Logout
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () async {
                await CacheService.clearUserData();
                await Supabase.instance.client.auth.signOut();
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.red, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Log Out',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _profileMenuItem(
      IconData icon,
      String title,
      String subtitle,
      Color bgColor,
      Color iconColor,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
                size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: 1,
    color: AppColors.surfaceContainerHighest,
  );
}