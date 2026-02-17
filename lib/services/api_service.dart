import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'http://192.168.50.113:8000'});

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      uri,
      headers: _jsonHeaders(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logHttpError(response);
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logHttpError(response);
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('Token not found in response');
    }
    return token;
  }

  Future<List<Task>> fetchTasks(String token) async {
    final uri = Uri.parse('$baseUrl/tasks/');
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logHttpError(response);
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Task> createTask(String token, String title) async {
    final uri = Uri.parse('$baseUrl/tasks/');
    final response = await http.post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logHttpError(response);
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Task.fromJson(data);
  }

  Future<Task> updateTaskStatus(String token, Task task) async {
    return updateTask(
      token,
      task.id,
      title: task.title,
      done: !task.done,
    );
  }

  Future<Task> updateTask(
    String token,
    int id, {
    String? title,
    bool? done,
  }) async {
    final uri = Uri.parse('$baseUrl/tasks/$id');
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (done != null) body['is_done'] = done;
    if (body.isEmpty) {
      throw ApiException('Nothing to update');
    }

    final response = await http.patch(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logHttpError(response);
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Task.fromJson(data);
  }

  Future<void> deleteTask(String token, int id) async {
    final uri = Uri.parse('$baseUrl/tasks/$id');
    final response = await http.delete(uri, headers: _authHeaders(token));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logHttpError(response);
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, String> _jsonHeaders() {
    return {'Content-Type': 'application/json'};
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _logHttpError(http.Response response) {
    dev.log(
      'HTTP ${response.statusCode} ${response.request?.method} ${response.request?.url}',
    );
    dev.log('Response body: ${response.body}');
  }

  String _errorMessage(http.Response response) {
    final status = response.statusCode;
    if (status == 401) return 'Unauthorized';
    if (response.body.isEmpty) return 'Request failed ($status)';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
      if (data is Map && data['detail'] is List) {
        final detailList = data['detail'] as List<dynamic>;
        final messages = detailList
            .whereType<Map<String, dynamic>>()
            .map((item) => item['msg'])
            .whereType<String>()
            .toList();
        if (messages.isNotEmpty) {
          return messages.join(', ');
        }
      }
    } catch (_) {
      // Ignore parse errors, fall back to status.
    }
    return 'Request failed ($status)';
  }
}
