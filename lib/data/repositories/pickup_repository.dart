import 'package:supabase_flutter/supabase_flutter.dart';

class PickupRepository {
  final _supabase = Supabase.instance.client;

  // Fetch all pending requests for a specific food
  Future<List<Map<String, dynamic>>> getRequestsForFood(String foodId) async {
    final data = await _supabase
        .from('pickup_requests')
        .select('*, users!pickup_requests_ngo_id_fkey(name, email)')
        .eq('food_id', foodId)
        .eq('status', 'pending')
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  // Accept a request → set request to accepted, food to reserved
  Future<void> acceptRequest(String requestId, String foodId) async {
    await _supabase
        .from('pickup_requests')
        .update({'status': 'accepted'})
        .eq('id', requestId);

    await _supabase
        .from('foods')
        .update({'status': 'reserved'})
        .eq('id', foodId);
  }

  // Reject a request → food stays available
  Future<void> rejectRequest(String requestId) async {
    await _supabase
        .from('pickup_requests')
        .update({'status': 'rejected'})
        .eq('id', requestId);
  }

  // Mark pickup as completed → both tables updated
  Future<void> completePickup(String requestId, String foodId) async {
    await _supabase
        .from('pickup_requests')
        .update({'status': 'completed'})
        .eq('id', requestId);

    await _supabase
        .from('foods')
        .update({'status': 'completed'})
        .eq('id', foodId);
  }

  Future<void> requestPickup(String foodId, String donorId) async {
    final ngoId = _supabase.auth.currentUser!.id;

    final existing = await _supabase
        .from('pickup_requests')
        .select()
        .eq('food_id', foodId)
        .eq('ngo_id', ngoId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You already requested this food');
    }

    await _supabase.from('pickup_requests').insert({
      'food_id': foodId,
      'ngo_id': ngoId,
      'donor_id': donorId,
      'status': 'pending',
    });
  }
}