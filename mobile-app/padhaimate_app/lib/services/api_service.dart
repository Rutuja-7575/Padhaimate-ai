import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class ApiService {
  // Emulator/device notes:
  // - Android emulator: use 10.0.2.2 instead of localhost
  // - iOS simulator: localhost works fine
  // - physical device: use your computer's LAN IP, e.g. http://192.168.1.5:8000
  static const String baseUrl = 'http://192.168.31.65:8000';

  static Future<Map<String, dynamic>> checkHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> queryDocuments(String question) async {
    final response = await http.post(
      Uri.parse('$baseUrl/query'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getDocuments() async {
    final response = await http.get(Uri.parse('$baseUrl/documents'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteDocument(String filename) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/documents/$filename'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadDocument(PlatformFile file) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);

    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );
    } else if (file.path != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path!, filename: file.name),
      );
    } else {
      throw Exception('Could not read the selected file.');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(decoded['detail'] ?? 'Upload failed');
    }
    return decoded;
  }
}