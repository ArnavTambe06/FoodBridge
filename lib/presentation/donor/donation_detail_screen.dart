import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/food.dart';
import '../../data/models/pickup_request.dart';
import '../../data/repositories/pickup_repository.dart';

class DonationDetailScreen extends StatefulWidget {
  final Food food;

  const DonationDetailScreen({super.key, required this.food});

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  final _pickupRepo = PickupRepository();
  List<PickupRequest> _requests = [];
  bool _isLoading = true;
  String? _actionInProgress; // tracks which request is being acted on

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await _pickupRepo.getRequestsForFood(widget.food.id);
      setState(() {
        _requests = data.map((e) => PickupRequest.fromJson(e)).toList();
      });
    } catch (e) {
      _showSnackbar('Failed to load requests: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(
      String requestId, String action) async {
    setState(() => _actionInProgress = requestId);
    try {
      switch (action) {
        case 'accept':
          await _pickupRepo.acceptRequest(requestId, widget.food.id);
          _showSnackbar('Request accepted! Food marked as reserved.');
          break;
        case 'reject':
          await _pickupRepo.rejectRequest(requestId);
          _showSnackbar('Request rejected.');
          break;
        case 'complete':
          await _pickupRepo.completePickup(requestId, widget.food.id);
          _showSnackbar('Pickup marked as completed! 🎉');
          break;
      }
      await _loadRequests(); // refresh list
    } catch (e) {
      _showSnackbar('Action failed: ${e.toString()}', isError: true);
    } finally {
      setState(() => _actionInProgress = null);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('Donation Detail'),
        backgroundColor: const Color(0xFF1B6B3A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1B6B3A),
        onRefresh: _loadRequests,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFoodInfoCard(),
            const SizedBox(height: 20),
            const Text(
              'INCOMING PICKUP REQUESTS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF1B6B3A)))
            else if (_requests.isEmpty)
              _buildNoRequestsState()
            else
              ..._requests.map((r) => _buildRequestCard(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodInfoCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel
          if (widget.food.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: widget.food.imageUrls.length,
                  itemBuilder: (context, index) => CachedNetworkImage(
                    imageUrl: widget.food.imageUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.grey[200],
                            child: const Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.food.foodName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    _statusBadge(widget.food.status),
                  ],
                ),
                const SizedBox(height: 6),
                _infoRow(Icons.scale_outlined, widget.food.quantity),
                if (widget.food.description.isNotEmpty)
                  _infoRow(Icons.notes_outlined, widget.food.description),
                _infoRow(
                    Icons.timer_off_outlined,
                    'Expires ${_formatExpiry(widget.food.expiryTime)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(PickupRequest request) {
    final isActing = _actionInProgress == request.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE8F5EE),
                child: Icon(Icons.people_alt_rounded,
                    color: Color(0xFF1B6B3A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.ngoName ?? 'NGO',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (request.ngoEmail != null)
                      Text(request.ngoEmail!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                _timeAgo(request.createdAt),
                style:
                const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isActing)
            const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1B6B3A)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(request.id, 'reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(request.id, 'accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6B3A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(request.id, 'complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNoRequestsState() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('No pending requests yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey)),
          SizedBox(height: 4),
          Text('NGOs nearby will send requests when they see your food',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    ),
  );

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Colors.grey))),
      ],
    ),
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
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}