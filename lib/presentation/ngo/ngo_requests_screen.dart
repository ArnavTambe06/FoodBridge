// lib/presentation/ngo/ngo_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cache_service.dart';
import '../../core/utils/error_handler.dart';

class NgoRequestsScreen extends StatefulWidget {
  const NgoRequestsScreen({super.key});

  @override
  State<NgoRequestsScreen> createState() => _NgoRequestsScreenState();
}

class _NgoRequestsScreenState extends State<NgoRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _channel;
  late TabController _tabController;

  // Filter tabs
  final _tabs = ['All', 'Pending', 'Accepted', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadRequests();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeToRealtime() {
    final ngoId = _supabase.auth.currentUser!.id;
    _channel = _supabase
        .channel('ngo_requests_$ngoId')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'pickup_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'ngo_id',
        value: ngoId,
      ),
      callback: (payload) => _loadRequests(),
    )
        .subscribe();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ngoId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('pickup_requests')
          .select(
          '*, foods(food_name, image_urls, quantity, expiry_time)')
          .eq('ngo_id', ngoId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(data);
      await CacheService.saveNgoRequests(list);
      setState(() => _requests = list);
    } catch (e) {
      final cached = await CacheService.loadNgoRequests();
      if (cached != null && cached.isNotEmpty) {
        setState(() => _requests = cached);
      } else {
        setState(() => _errorMessage = ErrorHandler.parseError(e));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filteredRequests(String filter) {
    if (filter == 'All') return _requests;
    return _requests
        .where((r) =>
    (r['status'] as String).toLowerCase() ==
        filter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // App bar
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
                          'My Requests',
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Live updates',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: _loadRequests,
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
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Summary chips
          if (!_isLoading && _errorMessage == null)
            SliverToBoxAdapter(
              child: _buildSummaryRow(),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Tab bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  indicator: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  tabs: _tabs
                      .map((t) => Tab(text: t))
                      .toList(),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Content
          if (_isLoading)
            const SliverToBoxAdapter(
              child: _ShimmerRequestList(),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: _buildErrorState(),
            )
          else
            SliverPadding(
              padding:
              const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: Builder(
                builder: (context) {
                  final filtered = _filteredRequests(
                      _tabs[_tabController.index]);
                  if (filtered.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(
                          _tabs[_tabController.index]),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                        padding:
                        const EdgeInsets.only(bottom: 14),
                        child: _RequestCard(
                            item: filtered[index]),
                      ),
                      childCount: filtered.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final pending = _requests
        .where((r) => r['status'] == 'pending')
        .length;
    final accepted = _requests
        .where((r) => r['status'] == 'accepted')
        .length;
    final completed = _requests
        .where((r) => r['status'] == 'completed')
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _summaryChip('$pending', 'Pending',
              AppColors.secondaryContainer.withOpacity(0.4),
              AppColors.secondary),
          const SizedBox(width: 8),
          _summaryChip('$accepted', 'Accepted',
              AppColors.primaryFixed.withOpacity(0.5),
              AppColors.primary),
          const SizedBox(width: 8),
          _summaryChip('$completed', 'Completed',
              AppColors.surfaceContainerHighest,
              AppColors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _summaryChip(
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

  Widget _buildEmptyState(String filter) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.assignment_outlined,
              color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          filter == 'All'
              ? 'No requests yet'
              : 'No $filter requests',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Browse the map to discover\nnearby food donations.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.error_outline_rounded,
                color: Colors.red[400], size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load requests',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadRequests,
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

// ── Request Card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _RequestCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final food = item['foods'] as Map<String, dynamic>?;
    final status = item['status'] as String;
    final createdAt = DateTime.parse(item['created_at'] as String);
    final imageUrls =
    List<String>.from(food?['image_urls'] ?? []);
    final expiryTime = food?['expiry_time'] != null
        ? DateTime.parse(food!['expiry_time'] as String)
        : null;

    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);

    return Container(
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
          // Top row — food info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageUrls.isNotEmpty
                      ? Image.network(
                    imageUrls.first,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _placeholder(),
                  )
                      : _placeholder(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food?['food_name'] ?? 'Food',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        food?['quantity'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (expiryTime != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 11,
                                color: AppColors.onSurfaceVariant
                                    .withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              _formatExpiry(expiryTime),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color:
                                AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() +
                        status.substring(1),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status message bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status),
                    size: 14, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage(status),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
                Text(
                  _timeAgo(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: statusColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(Icons.fastfood_outlined,
        color: AppColors.onSurfaceVariant.withOpacity(0.4),
        size: 28),
  );

  Color _statusColor(String status) => switch (status) {
    'pending' => AppColors.secondary,
    'accepted' => AppColors.primary,
    'rejected' => Colors.red,
    'completed' => AppColors.onSurfaceVariant,
    _ => AppColors.onSurfaceVariant,
  };

  Color _statusBg(String status) => switch (status) {
    'pending' =>
        AppColors.secondaryContainer.withOpacity(0.35),
    'accepted' => AppColors.primaryFixed.withOpacity(0.4),
    'rejected' => Colors.red.withOpacity(0.08),
    'completed' => AppColors.surfaceContainerHighest,
    _ => AppColors.surfaceContainerHighest,
  };

  IconData _statusIcon(String status) => switch (status) {
    'pending' => Icons.hourglass_top_rounded,
    'accepted' => Icons.check_circle_rounded,
    'rejected' => Icons.cancel_rounded,
    'completed' => Icons.task_alt_rounded,
    _ => Icons.info_rounded,
  };

  String _statusMessage(String status) => switch (status) {
    'pending' => 'Waiting for donor to respond...',
    'accepted' => 'Approved! Go collect the food.',
    'rejected' => 'Donor declined this request.',
    'completed' => 'Successfully collected.',
    _ => '',
  };

  String _formatExpiry(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours < 1) return 'Expires in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Expires in ${diff.inHours}h';
    return 'Expires ${dt.day}/${dt.month}/${dt.year}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ShimmerRequestList extends StatelessWidget {
  const _ShimmerRequestList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        children: List.generate(
          4,
              (_) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 130,
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