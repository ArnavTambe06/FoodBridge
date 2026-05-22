import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cloudinary_repository.dart';

class FoodRepository {
  final _supabase = Supabase.instance.client;
  final _cloudinaryRepo = CloudinaryRepository();

  Future<void> postFood({
    required String foodName,
    required String quantity,
    required String description,
    required DateTime expiryTime,
    required double lat,
    required double lng,
    required List<File> images,
    void Function(double progress)? onUploadProgress,
  }) async {
    // ← Safety check instead of !
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be logged in to post food.');
    }

    // Step 1 — Upload all images to Cloudinary
    final imageUrls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final url = await _cloudinaryRepo.uploadImage(images[i]);
      if (url != null) imageUrls.add(url);
      onUploadProgress?.call((i + 1) / images.length);
    }

    // Step 2 — Save food record to Supabase
    await _supabase.from('foods').insert({
      'donor_id': userId,
      'food_name': foodName,
      'quantity': quantity,
      'description': description,
      'image_urls': imageUrls,
      'location': 'POINT($lng $lat)',
      'expiry_time': expiryTime.toIso8601String(),
      'status': 'available',
    });
  }
}