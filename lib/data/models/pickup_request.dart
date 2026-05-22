class PickupRequest {
  final String id;
  final String foodId;
  final String ngoId;
  final String donorId;
  final String status;
  final DateTime createdAt;
  final String? ngoName;
  final String? ngoEmail;

  PickupRequest({
    required this.id,
    required this.foodId,
    required this.ngoId,
    required this.donorId,
    required this.status,
    required this.createdAt,
    this.ngoName,
    this.ngoEmail,
  });

  factory PickupRequest.fromJson(Map<String, dynamic> json) {
    final ngoData = json['users'] as Map<String, dynamic>?;
    return PickupRequest(
      id: json['id'] as String,
      foodId: json['food_id'] as String,
      ngoId: json['ngo_id'] as String,
      donorId: json['donor_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      ngoName: ngoData?['name'] as String?,
      ngoEmail: ngoData?['email'] as String?,
    );
  }
}