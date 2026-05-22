import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/food.dart';
import '../../data/repositories/pickup_repository.dart';

class NgoFoodDetailScreen extends StatefulWidget {
  final Food food;

  const NgoFoodDetailScreen({super.key, required this.food});

  @override
  State<NgoFoodDetailScreen> createState() => _NgoFoodDetailScreenState();
}

class _NgoFoodDetailScreenState extends State<NgoFoodDetailScreen> {
  final _pickupRepo = PickupRepository();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isRequesting = false;
  bool _alreadyRequested = false;
  String? _donorName;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
    _fetchDonorName();
  }

  Future<void> _checkExistingRequest() async {
    try {
      final ngoId = _supabase.auth.currentUser!.id;
      final existing = await _supabase
          .from('pickup_requests')
          .select()
          .eq('food_id', widget.food.id)
          .eq('ngo_id', ngoId)
          .maybeSingle();

      setState(() {
        _alreadyRequested = existing != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDonorName() async {
    try {
      final data = await _supabase
          .from('users')
          .select('name')
          .eq('id', widget.food.donorId)
          .single();

      setState(() => _donorName = data['name'] as String?);
    } catch (_) {}
  }

  Future<void> _requestPickup() async {
    setState(() => _isRequesting = true);
    try {
      await _pickupRepo.requestPickup(
        widget.food.id,
        widget.food.donorId,
      );
      setState(() => _alreadyRequested = true);
      _showSnackbar('Pickup requested! Waiting for donor to respond. 🎉');
    } catch (e) {
      _showSnackbar(e.toString().replaceAll('Exception: ', ''),
          isError: true);
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red[700] : const Color(0xFF1B6B3A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: CustomScrollView(
        slivers: [
          // Image carousel app bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1B6B3A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: food.imageUrls.isNotEmpty
                  ? Stack(
                children: [
                  PageView.builder(
                    itemCount: food.imageUrls.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) =>
                        CachedNetworkImage(
                          imageUrl: food.imageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[200]),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image_outlined,
                                size: 48, color: Colors.grey),
                          ),
                        ),
                  ),
                  // Image index dots
                  if (food.imageUrls.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          food.imageUrls.length,
                              (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            width: _currentImageIndex == i ? 16 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i
                                  ? Colors.white
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
                  : Container(
                color: const Color(0xFF1B6B3A),
                child: const Icon(Icons.fastfood_outlined,
                    size: 80, color: Colors.white54),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          food.foodName,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _statusBadge(food.status),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info cards
                  _buildInfoGrid(food),

                  const SizedBox(height: 16),

                  // Description
                  if (food.description.isNotEmpty) ...[
                    _buildSectionLabel('Description'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Text(food.description,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Donor info
                  _buildSectionLabel('Posted By'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFFE8F5EE),
                          child: Icon(Icons.person,
                              color: Color(0xFF1B6B3A), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _donorName ?? 'Loading...',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Request Pickup bottom button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -4))
          ],
        ),
        child: _isLoading
            ? const Center(
            child:
            CircularProgressIndicator(color: Color(0xFF1B6B3A)))
            : SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: (_alreadyRequested ||
                food.status != 'available' ||
                _isRequesting)
                ? null
                : _requestPickup,
            style: ElevatedButton.styleFrom(
              backgroundColor: _alreadyRequested
                  ? Colors.grey[300]
                  : const Color(0xFF1B6B3A),
              foregroundColor: _alreadyRequested
                  ? Colors.grey[600]
                  : Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isRequesting
                ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : Text(
              _alreadyRequested
                  ? '✓ Already Requested'
                  : food.status != 'available'
                  ? 'Food No Longer Available'
                  : 'Request Pickup',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid(Food food) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [
        _infoTile(Icons.scale_outlined, 'Quantity', food.quantity),
        _infoTile(Icons.timer_off_outlined, 'Expires',
            _formatExpiry(food.expiryTime)),
        _infoTile(Icons.location_on_outlined, 'Distance',
            food.distanceM != null
                ? '${(food.distanceM! / 1000).toStringAsFixed(1)} km away'
                : 'Nearby'),
        _infoTile(Icons.check_circle_outline, 'Status',
            food.status[0].toUpperCase() + food.status.substring(1)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1B6B3A)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.5)),
  );

  Widget _statusBadge(String status) {
    final color = switch (status) {
      'available' => Colors.green,
      'reserved' => Colors.orange,
      'completed' => Colors.grey,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _formatExpiry(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours < 1) return 'in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}