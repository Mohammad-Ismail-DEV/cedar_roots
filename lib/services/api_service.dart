import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServices {
  static final ApiServices _instance = ApiServices._internal();

  factory ApiServices() => _instance;

  ApiServices._internal();

  final String baseUrl = 'http://13.50.2.82:3000';
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
  Future<String?> uploadFile(XFile file) async {
    final req = http.MultipartRequest(
      "POST",
      Uri.parse("http://13.50.2.82:3000/upload"),
    );
    req.files.add(await http.MultipartFile.fromPath('file', file.path));

    if (_token != null) {
      req.headers['Authorization'] = 'Bearer $_token';
    }

    final response = await req.send();
    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final json = jsonDecode(resBody);
      return json['url'];
    } else {
      return null;
    }
  }

  Future<http.Response> fetchUserConnections(userId) {
    return http.get(
      Uri.parse('$baseUrl/connections/user/$userId'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> createOrganization(Map<String, dynamic> data) {
    return http.post(
      Uri.parse('$baseUrl/organizations'),
      headers: _headersWithAuth(),
      body: jsonEncode(data),
    );
  }

  Future<http.Response> fetchUserOrganizations(int userId) {
    return http.get(
      Uri.parse('$baseUrl/organizations/user/$userId'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> fetchOrganizationById(int organizationId) {
    return http.get(
      Uri.parse('$baseUrl/organizations/$organizationId'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> deleteOrganization(int id) {
    return http.delete(
      Uri.parse('$baseUrl/organizations/$id'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> getOrganizationMembers(int organizationId) {
    return http.get(
      Uri.parse('$baseUrl/organization_members/$organizationId'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> addOrganizationMember({
    required int userId,
    required int organizationId,
    required String role,
  }) {
    return http.post(
      Uri.parse('$baseUrl/organization_members'),
      headers: _headersWithAuth(),
      body: jsonEncode({
        'user_id': userId,
        'organization_id': organizationId,
        'role': role,
      }),
    );
  }

  Future<http.Response> cancelConnectionRequest(int connectionId) {
    return http.delete(
      Uri.parse('$baseUrl/connections/$connectionId'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> getConnectionBetween(int user1Id, int user2Id) {
    return http.get(
      Uri.parse('$baseUrl/connections/between/$user1Id/$user2Id'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> respondToRequest(Map<String, dynamic> data) {
    return http.put(
      Uri.parse('$baseUrl/connections/respond'),
      headers: _headersWithAuth(),
      body: jsonEncode(data),
    );
  }

  Future<http.Response> followOrganization(int organizationId) {
    return http.post(
      Uri.parse('$baseUrl/organization_followers'),
      headers: _headersWithAuth(),
      body: jsonEncode({'organization_id': organizationId}),
    );
  }

  // Unfollow organization
  Future<http.Response> unfollowOrganization(int organizationId) {
    return http.delete(
      Uri.parse('$baseUrl/organization_followers'),
      headers: _headersWithAuth(),
      body: jsonEncode({'organization_id': organizationId}),
    );
  }

  Future<http.Response> removeConnection(int connectionId) {
    return http.delete(
      Uri.parse('$baseUrl/connections/$connectionId'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> acceptConnection(int connectionId) {
    return http.put(
      Uri.parse('$baseUrl/connections/$connectionId'),
      headers: _headersWithAuth(),
      body: jsonEncode({'status': 'accepted'}),
    );
  }

  Future<http.Response> rejectConnection(int connectionId) {
    return http.put(
      Uri.parse('$baseUrl/connections/$connectionId'),
      headers: _headersWithAuth(),
      body: jsonEncode({'status': 'rejected'}),
    );
  }

  Future<http.Response> updateOrganizationMemberRole({
    required int userId,
    required int organizationId,
    required String role,
  }) {
    return http.put(
      Uri.parse('$baseUrl/organization_members/role'),
      headers: _headersWithAuth(),
      body: jsonEncode({
        'user_id': userId,
        'organization_id': organizationId,
        'role': role,
      }),
    );
  }

  Future<http.Response> removeOrganizationMember({
    required int userId,
    required int organizationId,
  }) {
    return http.delete(
      Uri.parse('$baseUrl/organization_members'),
      headers: _headersWithAuth(),
      body: jsonEncode({'user_id': userId, 'organization_id': organizationId}),
    );
  }

  Future<http.Response> searchUsersByName(String query) {
    return http.get(
      Uri.parse('$baseUrl/users?search=$query'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> getOrganizationById(int id) {
    return http.get(
      Uri.parse('$baseUrl/organizations/$id'),
      headers: _headersWithAuth(),
    );
  }

  Future<http.Response> updateOrganization(int id, Map<String, dynamic> data) {
    return http.put(
      Uri.parse('$baseUrl/organizations/$id'),
      headers: _headersWithAuth(),
      body: jsonEncode(data),
    );
  }

  // Create Event
  Future<http.Response> createEvent(Map<String, dynamic> data) {
    return http.post(
      Uri.parse('$baseUrl/events'),
      headers: _headersWithAuth(),
      body: jsonEncode(data),
    );
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

  Future<http.Response> sendConnectionRequest(receiverId) async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getInt('user_id');

    return http.post(
      Uri.parse('$baseUrl/connections'),
      headers: _headersWithAuth(),
      body: json.encode({
        'sender_id': senderId,
        'receiver_id': receiverId, // intentionally keeping your spelling
        'status': 'pending',
      }),
    );
  }

  Future<http.Response> updatePost(int postId, Map<String, dynamic> data) {
    return http.put(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: _headersWithAuth(),
      body: jsonEncode(data),
    );
  }

  // Create a new post
  Future<http.Response> createPost({
    required String content,
    String? imageUrl,
  }) {
    final data = {
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    return http.post(
      Uri.parse('$baseUrl/posts'),
      headers: _headersWithAuth(),
      body: jsonEncode(data),
    );
  }

  // Fetch all posts (with user, comments, likes)
  Future<List<dynamic>> fetchPosts([int? userId]) async {
    final query = userId != null ? '?user_id=$userId' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/posts$query'),
      headers: _headersWithAuth(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<List<dynamic>> fetchEvents([int? userId]) async {
    final query = userId != null ? '?user_id=$userId' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/events$query'),
      headers: _headersWithAuth(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load events');
    }
  }

  // Fetch a single post by ID
  Future<Map<String, dynamic>> fetchPostById(int postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: _headersWithAuth(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Post not found');
    }
  }

  // Delete a post by ID (only author can delete)
  Future<http.Response> deletePost(int postId) {
    return http.delete(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: _headersWithAuth(),
    );
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
