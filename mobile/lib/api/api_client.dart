import 'dart:convert';

import 'package:http/http.dart' as http;

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://covatest-production.up.railway.app',
);

class ApiException implements Exception {
  ApiException(this.message, {this.status});
  final String message;
  final int? status;

  @override
  String toString() => message;
}

class AuthSession {
  AuthSession({
    required this.token,
    required this.email,
    required this.fullName,
  });

  final String token;
  final String email;
  final String fullName;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
    );
  }
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final String updatedAt;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'TODO',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class ApiClient {
  Future<AuthSession> login(String email, String password) async {
    return _auth('/api/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<AuthSession> register(
    String fullName,
    String email,
    String password,
  ) async {
    return _auth('/api/auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<AuthSession> _auth(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final map = _decodeMap(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AuthSession.fromJson(map);
    }
    throw ApiException(
      map['message']?.toString() ?? 'Echec de la requete',
      status: response.statusCode,
    );
  }

  Future<List<TaskItem>> listTasks(
    String token, {
    String? status,
    String? search,
  }) async {
    final params = <String, String>{};
    if (status != null && status != 'ALL') params['status'] = status;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final uri = Uri.parse('$apiBaseUrl/api/tasks').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 401) {
      throw ApiException('Session expiree', status: 401);
    }
    if (response.statusCode != 200) {
      final map = _tryMap(response.body);
      throw ApiException(
        map?['message']?.toString() ?? 'Impossible de charger les taches',
        status: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TaskItem.fromJson)
        .toList();
  }

  Future<TaskItem> createTask(
    String token, {
    required String title,
    required String description,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/tasks'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
      }),
    );
    return _taskResult(response, 'Echec de la creation');
  }

  Future<TaskItem> updateTask(
    String token,
    int id, {
    required String title,
    required String description,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl/api/tasks/$id'),
      headers: _headers(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
      }),
    );
    return _taskResult(response, 'Echec de la mise a jour');
  }

  Future<void> deleteTask(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/api/tasks/$id'),
      headers: _headers(token),
    );
    if (response.statusCode == 401) {
      throw ApiException('Session expiree', status: 401);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final map = _tryMap(response.body);
      throw ApiException(
        map?['message']?.toString() ?? 'Echec de la suppression',
        status: response.statusCode,
      );
    }
  }

  TaskItem _taskResult(http.Response response, String fallback) {
    if (response.statusCode == 401) {
      throw ApiException('Session expiree', status: 401);
    }
    final map = _decodeMap(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return TaskItem.fromJson(map);
    }
    throw ApiException(
      map['message']?.toString() ?? fallback,
      status: response.statusCode,
    );
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decodeMap(http.Response response) {
    final map = _tryMap(response.body);
    if (map == null) {
      throw ApiException(
        'Reponse invalide du serveur',
        status: response.statusCode,
      );
    }
    return map;
  }

  Map<String, dynamic>? _tryMap(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
