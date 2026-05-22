class Food {
  final String id;
  final String donorId;
  final String foodName;
  final String quantity;
  final String description;
  final List<String> imageUrls;
  final String location;
  final DateTime expiryTime;
  final String status;
  final DateTime createdAt;
  final double? distanceM;

  Food({
    required this.id,
    required this.donorId,
    required this.foodName,
    required this.quantity,
    required this.description,
    required this.imageUrls,
    required this.location,
    required this.expiryTime,
    required this.status,
    required this.createdAt,
    this.distanceM,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      donorId: json['donor_id'] as String? ?? '',        // ← nullable
      foodName: json['food_name'] as String? ?? '',      // ← nullable
      quantity: json['quantity'] as String? ?? '',       // ← nullable
      description: json['description'] as String? ?? '', // ← nullable
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      location: json['location'] as String? ?? '',       // ← nullable
      expiryTime: DateTime.parse(
          json['expiry_time'] as String? ?? DateTime.now().toIso8601String()),
      status: json['status'] as String? ?? 'available', // ← nullable
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),                              // ← nullable
      distanceM: (json['distance_m'] as num?)?.toDouble(),
    );
  }
}