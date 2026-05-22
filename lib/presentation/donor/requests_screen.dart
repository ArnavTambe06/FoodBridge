// lib/presentation/donor/requests_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cache_service.dart';
import '../../core/utils/error_handler.dart';
import '../../data/repositories/pickup_repository.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  final _pickupRepo = PickupRepository();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _actionInProgress;
  RealtimeChannel? _channel;
  late TabController _tabController;

  final _tabs = ['All', 'Pending', 'Accepted', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _tabs.length, vsync: this);
    _loadAllRequests();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeToRealtime() {
    final userId = _supabase.auth.currentUser!.id;
    _channel = _supabase
        .channel('donor_requests_$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'pickup_requests',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'donor_id',
        value: userId,
      ),
      callback: (payload) => _loadAllRequests(),
    )
        .subscribe();
  }

  Future<void> _loadAllRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('pickup_requests')
          .select(
          '*, users!pickup_requests_ngo_id_fkey(name, email), foods(food_name, image_urls, status, quantity)')
          .eq('donor_id', userId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(data);
      await CacheService.saveMyRequests(list);
      setState(() => _requests = list);
    } catch (e) {
      final cached = await CacheService.loadMyRequests();
      if (cached != null && cached.isNotEmpty) {
        setState(() => _requests = cached);
      } else {
        setState(
                () => _errorMessage = ErrorHandler.parseError(e));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(
      String requestId, String foodId, String action) async {
    setState(() => _actionInProgress = requestId);
    try {
      switch (action) {
        case 'accept':
          await _pickupRepo.acceptRequest(requestId, foodId);
          ErrorHandler.showSuccess(
              context, 'Request accepted! Food marked as reserved.');
          break;
        case 'reject':
          await _pickupRepo.rejectRequest(requestId);
          ErrorHandler.showSuccess(context, 'Request rejected.');
          break;
        case 'complete':
          await _pickupRepo.completePickup(requestId, foodId);
          ErrorHandler.showSuccess(
              context, 'Pickup marked as completed! 🎉');
          break;
      }
      await _loadAllRequests();
    } catch (e) {
      ErrorHandler.showError(
          context, ErrorHandler.parseError(e));
    } finally {
      setState(() => _actionInProgress = null);
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
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requests',
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
                  GestureDetector(
                    onTap: _loadAllRequests,
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
              padding:
              const EdgeInsets.symmetric(horizontal: 24),
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
                        color: AppColors.onSurface
                            .withOpacity(0.06),
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
                  unselectedLabelColor:
                  AppColors.onSurfaceVariant,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
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
                        child: _DonorRequestCard(
                          item: filtered[index],
                          actionInProgress: _actionInProgress,
                          onAction: _handleAction,
                        ),
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
          _summaryChip(
              '$pending',
              'Pending',
              AppColors.secondaryContainer.withOpacity(0.4),
              AppColors.secondary),
          const SizedBox(width: 8),
          _summaryChip(
              '$accepted',
              'Accepted',
              AppColors.primaryFixed.withOpacity(0.5),
              AppColors.primary),
          const SizedBox(width: 8),
          _summaryChip(
              '$completed',
              'Completed',
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
          child: const Icon(Icons.inbox_outlined,
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
          'NGOs will send requests when\nthey see your food donations.',
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
            onTap: _loadAllRequests,
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

// ── Donor Request Card ────────────────────────────────────────────────────────

class _DonorRequestCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? actionInProgress;
  final Function(String, String, String) onAction;

  const _DonorRequestCard({
    required this.item,
    required this.actionInProgress,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final requestId = item['id'] as String;
    final foodId = item['food_id'] as String;
    final ngo = item['users'] as Map<String, dynamic>?;
    final food = item['foods'] as Map<String, dynamic>?;
    final status = item['status'] as String;
    final createdAt =
    DateTime.parse(item['created_at'] as String);
    final imageUrls =
    List<String>.from(food?['image_urls'] ?? []);
    final isActing = actionInProgress == requestId;
    final isPending = status == 'pending';

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
          // Food + NGO info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Food thumbnail
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
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer
                                  .withOpacity(0.5),
                              borderRadius:
                              BorderRadius.circular(6),
                            ),
                            child: const Icon(
                                Icons.people_alt_rounded,
                                size: 12,
                                color: AppColors.secondary),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ngo?['name'] ?? 'NGO',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color:
                                AppColors.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge (non-pending)
                if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusBg(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status[0].toUpperCase() +
                          status.substring(1),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Action buttons (pending only) or status bar
          if (isPending)
            Padding(
              padding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: isActing
                  ? Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              )
                  : Row(
                children: [
                  // Reject
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onAction(
                          requestId, foodId, 'reject'),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.red
                              .withOpacity(0.08),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Reject',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accept
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => onAction(
                          requestId, foodId, 'accept'),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                          BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Accept Pickup',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mark Done
                  GestureDetector(
                    onTap: () => onAction(
                        requestId, foodId, 'complete'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors
                            .surfaceContainerHigh,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _statusBg(status),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(status),
                      size: 14, color: _statusColor(status)),
                  const SizedBox(width: 8),
                  Text(
                    _statusMessage(status),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(status),
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
    'accepted' => 'Accepted — NGO is on their way.',
    'rejected' => 'You declined this request.',
    'completed' => 'Pickup completed successfully.',
    _ => '',
  };

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
            height: 140,
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