import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cache_service.dart';
import '../common/about_screen.dart';
import 'ngo_map_screen.dart';
import 'ngo_requests_screen.dart';

class NgoDashboard extends ConsumerStatefulWidget {
  const NgoDashboard({super.key});

  @override
  ConsumerState<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends ConsumerState<NgoDashboard> {
  int _currentIndex = 0;

  void _switchTab(int index) => setState(() => _currentIndex = index);

  List<Widget> get _screens => [
    const NgoMapScreen(),
    const _AvailableFoodTab(),
    const NgoRequestsScreen(),
    _NgoProfileTab(onSwitchTab: _switchTab),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _screens[_currentIndex],
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
          _navItem(0, Icons.map_rounded, Icons.map_outlined, 'Map'),
          _navItem(1, Icons.restaurant_rounded,
              Icons.restaurant_outlined, 'Food'),
          _navItem(2, Icons.assignment_rounded,
              Icons.assignment_outlined, 'Requests'),
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

// ── Available Food Tab ────────────────────────────────────────────────────────

class _AvailableFoodTab extends StatelessWidget {
  const _AvailableFoodTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Food',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
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
                        child: const Icon(Icons.map_rounded,
                            color: AppColors.primary, size: 40),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Use the Map tab',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover nearby food donations\nvisually on the map.',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── NGO Profile Tab ───────────────────────────────────────────────────────────

class _NgoProfileTab extends StatelessWidget {
  final void Function(int) onSwitchTab;

  const _NgoProfileTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'NGO';

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

        // Profile card — Terracotta for NGO
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFFB05A3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.25),
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
                        Text(name,
                            style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8)),
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
                          child: Text('NGO',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
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
                    Icons.assignment_rounded,
                    'My Requests',
                    'Track your pickup requests',
                    AppColors.primaryFixed.withOpacity(0.6),
                    AppColors.primary,
                        () => onSwitchTab(2), // ← wired to Requests tab
                  ),
                  _divider(),
                  _profileMenuItem(
                    Icons.map_rounded,
                    'Find Food',
                    'Discover nearby donations on map',
                    AppColors.secondaryContainer.withOpacity(0.5),
                    AppColors.secondary,
                        () => onSwitchTab(0), // ← wired to Map tab
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