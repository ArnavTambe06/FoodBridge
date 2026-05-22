import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState
    extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  Future<void> _saveRole() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a role to continue.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId =
          Supabase.instance.client.auth.currentUser!.id;
      final email =
      Supabase.instance.client.auth.currentUser!.email!;
      final name = Supabase.instance.client.auth.currentUser!
          .userMetadata?['full_name'] ??
          'User';

      await Supabase.instance.client.from('users').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'role': _selectedRole,
      });

      ref.invalidate(userRoleProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving role: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // App name
              Text(
                'FoodBridge',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 32),

              // Headline
              Text(
                'How will you\nbridge the gap?',
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.02 * 36,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Join our community of surplus heroes. Select\nyour role to begin your journey.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 40),

              // Donor Card
              _RoleCard(
                title: "I'm a Donor",
                subtitle:
                'Hotels, restaurants, and event planners with surplus high-quality food looking to make an impact.',
                icon: Icons.restaurant_rounded,
                actionLabel: 'START DONATING',
                isSelected: _selectedRole == 'donor',
                isDonor: true,
                onTap: () =>
                    setState(() => _selectedRole = 'donor'),
              ),

              const SizedBox(height: 16),

              // NGO Card
              _RoleCard(
                title: "I'm an NGO",
                subtitle:
                'Charities, community kitchens, and relief organizations dedicated to nourishing those in need.',
                icon: Icons.favorite_rounded,
                actionLabel: 'RECEIVE SUPPORT',
                isSelected: _selectedRole == 'ngo',
                isDonor: false,
                onTap: () =>
                    setState(() => _selectedRole = 'ngo'),
              ),

              const SizedBox(height: 40),

              // Trust indicators
              _buildTrustRow(),

              const SizedBox(height: 40),

              // Continue Button
              GestureDetector(
                onTap: _isLoading ? null : _saveRole,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _selectedRole != null
                        ? const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: _selectedRole == null
                        ? AppColors.surfaceContainerHighest
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedRole != null
                        ? [
                      BoxShadow(
                        color:
                        AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                        : null,
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      'CONTINUE',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _selectedRole != null
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'This cannot be changed later.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color:
                    AppColors.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _trustItem(
            Icons.verified_rounded,
            'Verified Safety',
            'Strict health standards',
          ),
          const SizedBox(height: 16),
          _trustItem(
            Icons.bolt_rounded,
            'Real-time Matching',
            'Instant local logistics',
          ),
          const SizedBox(height: 16),
          _trustItem(
            Icons.eco_rounded,
            'Eco-Tracking',
            'Measure CO₂ reduction',
          ),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
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
      ],
    );
  }
}

// ── Role Card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final bool isSelected;
  final bool isDonor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.isSelected,
    required this.isDonor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isDonor
        ? AppColors.primaryFixed.withOpacity(0.8)
        : AppColors.secondaryContainer.withOpacity(0.8);
    final iconColor =
    isDonor ? AppColors.primary : AppColors.secondary;
    final actionColor =
    isDonor ? AppColors.primary : AppColors.secondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDonor
              ? AppColors.primaryFixed.withOpacity(0.3)
              : AppColors.secondaryContainer.withOpacity(0.3))
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withOpacity(0.06),
              blurRadius: 32,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Spacer(),
                // Selected indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? actionColor
                        : AppColors.surfaceContainerHighest,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                letterSpacing: -0.02 * 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: actionColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded,
                    color: actionColor, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}