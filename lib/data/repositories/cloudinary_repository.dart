import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryRepository {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME']!;

  static String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

  static String get _folder => dotenv.env['CLOUDINARY_FOLDER']!;

  Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = _folder
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    // ← ADD THIS to see what Cloudinary returns
    print('DEBUG Cloudinary response: $json');

    if (json['error'] != null) {
      throw Exception('Cloudinary error: ${json['error']['message']}');
    }

    return json['secure_url'] as String?;
  }
}