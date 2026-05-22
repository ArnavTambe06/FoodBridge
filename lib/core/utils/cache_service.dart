import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheService {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const _myDonationsKey = 'my_donations';
  static const _myRequestsKey = 'my_requests';
  static const _ngoRequestsKey = 'ngo_requests';
  static const _userProfileKey = 'user_profile';

  // ── Save ──────────────────────────────────────────────────────────────────

  static Future<void> saveMyDonations(List<Map<String, dynamic>> data) async {
    await _storage.write(
      key: _myDonationsKey,
      value: jsonEncode(data),
    );
  }

  static Future<void> saveMyRequests(List<Map<String, dynamic>> data) async {
    await _storage.write(
      key: _myRequestsKey,
      value: jsonEncode(data),
    );
  }

  static Future<void> saveNgoRequests(List<Map<String, dynamic>> data) async {
    await _storage.write(
      key: _ngoRequestsKey,
      value: jsonEncode(data),
    );
  }

  static Future<void> saveUserProfile(Map<String, dynamic> data) async {
    await _storage.write(
      key: _userProfileKey,
      value: jsonEncode(data),
    );
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>?> loadMyDonations() async {
    return _loadList(_myDonationsKey);
  }

  static Future<List<Map<String, dynamic>>?> loadMyRequests() async {
    return _loadList(_myRequestsKey);
  }

  static Future<List<Map<String, dynamic>>?> loadNgoRequests() async {
    return _loadList(_ngoRequestsKey);
  }

  static Future<Map<String, dynamic>?> loadUserProfile() async {
    final raw = await _storage.read(key: _userProfileKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<void> clearUserData() async {
    await _storage.delete(key: _myDonationsKey);
    await _storage.delete(key: _myRequestsKey);
    await _storage.delete(key: _ngoRequestsKey);
    await _storage.delete(key: _userProfileKey);
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>?> _loadList(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}