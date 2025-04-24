import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  final String baseUrl = 'http://13.48.155.59:3000';
  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Manually set token (e.g. after login)
  void setToken(String token) {
    _token = token;
  }

  // Auth
  Future<http.Response> login(String email, String password) {
    return http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  Future<http.Response> register(String name, String email, String password) {
    return http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
  }

  Future<http.Response> verifyCode(String email, String code) {
    return http.post(
      Uri.parse('$baseUrl/auth/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
  }

  // Upload file
  Future<String?> uploadFile(File file) async {
    final url = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', url);

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final fileType = mimeType.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType(fileType[0], fileType[1]),
      ),
    );

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final json = jsonDecode(resBody);
      return json['url'];
    } else {
      return null;
    }
  }

  // Create Event
  Future<http.Response> createEvent(Map<String, dynamic> data) {
    return http.post(
      Uri.parse('$baseUrl/events'),
      headers: _headersWithAuth(),
      body: jsonEncode(data),
    );
  }

  // Fetch Events
  Future<List<dynamic>> fetchEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: _headersWithAuth(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load events');
    }
  }

  // Get message summaries
  Future<List<dynamic>> getMessageSummaries(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/summary/$userId'),
      headers: _headersWithAuth(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load message summaries');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(int senderId, int receiverId) async {
    await http.post(
      Uri.parse('$baseUrl/messages/mark_as_read'),
      headers: _headersWithAuth(),
      body: jsonEncode({'senderId': senderId, 'receiverId': receiverId}),
    );
  }

  // Send group message
  Future<http.Response> sendGroupMessage(Map<String, dynamic> data) {
    return http.post(
      Uri.parse('$baseUrl/group-messages'),
      headers: _headersWithAuth(),
      body: jsonEncode(data),
    );
  }

  // Fetch group messages
  Future<List<dynamic>> fetchGroupMessages(int groupId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/group-messages/$groupId'),
      headers: _headersWithAuth(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load group messages');
    }
  }

  // Utility: build headers with token
  Map<String, String> _headersWithAuth() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }
}
