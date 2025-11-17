import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../models/task_model.dart';

/// DataSource remoto para comunicación con la API REST
class RemoteDataSource {
  final http.Client client;

  RemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  /// Headers comunes para todas las peticiones
  Map<String, String> _getHeaders({String? idempotencyKey}) {
    final headers = {
      'Content-Type': ApiConstants.contentType,
    };
    
    if (idempotencyKey != null) {
      headers[ApiConstants.idempotencyKeyHeader] = idempotencyKey;
    }
    
    return headers;
  }

  /// Maneja errores HTTP
  void _handleHttpError(int statusCode, String body) {
    if (statusCode >= 500) {
      throw ServerFailure('Error del servidor ($statusCode): $body');
    } else if (statusCode >= 400) {
      throw ClientFailure('Error en la solicitud ($statusCode): $body');
    } else {
      throw UnknownFailure('Error desconocido ($statusCode): $body');
    }
  }

  // ==================== OPERACIONES DE LA API ====================

  /// GET /tasks - Obtiene todas las tareas con filtros opcionales
  Future<List<TaskModel>> getTasks({bool? completed}) async {
    try {
      String url = '${ApiConstants.baseUrl}${ApiConstants.tasksEndpoint}';
      
      if (completed != null) {
        url += '?completed=${completed.toString()}';
      }

      final response = await client
          .get(
            Uri.parse(url),
            headers: _getHeaders(),
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        _handleHttpError(response.statusCode, response.body);
        return [];
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Error de conexión: $e');
    }
  }

  /// GET /tasks/{id} - Obtiene una tarea específica
  Future<TaskModel?> getTaskById(String id) async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.tasksEndpoint}/$id';

      final response = await client
          .get(
            Uri.parse(url),
            headers: _getHeaders(),
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TaskModel.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        _handleHttpError(response.statusCode, response.body);
        return null;
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Error de conexión: $e');
    }
  }

  /// POST /tasks - Crea una nueva tarea
  Future<TaskModel> createTask({
    required String title,
    String? idempotencyKey,
  }) async {
    try {
      final url = '${ApiConstants.baseUrl}${ApiConstants.tasksEndpoint}';

      final body = json.encode({
        'title': title,
        'completed': false,
      });

      final response = await client
          .post(
            Uri.parse(url),
            headers: _getHeaders(idempotencyKey: idempotencyKey),
            body: body,
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TaskModel.fromJson(jsonData);
      } else {
        _handleHttpError(response.statusCode, response.body);
        throw ServerFailure();
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Error de conexión: $e');
    }
  }

  /// PUT /tasks/{id} - Actualiza una tarea existente
  Future<TaskModel> updateTask({
    required String id,
    String? title,
    bool? completed,
  }) async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.tasksEndpoint}/$id';

      final Map<String, dynamic> updateData = {};
      if (title != null) updateData['title'] = title;
      if (completed != null) updateData['completed'] = completed;

      final body = json.encode(updateData);

      final response = await client
          .put(
            Uri.parse(url),
            headers: _getHeaders(),
            body: body,
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TaskModel.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw ClientFailure('Tarea no encontrada');
      } else {
        _handleHttpError(response.statusCode, response.body);
        throw ServerFailure();
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Error de conexión: $e');
    }
  }

  /// DELETE /tasks/{id} - Elimina una tarea
  Future<void> deleteTask(String id) async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.tasksEndpoint}/$id';

      final response = await client
          .delete(
            Uri.parse(url),
            headers: _getHeaders(),
          )
          .timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return; // Éxito
      } else if (response.statusCode == 404) {
        throw ClientFailure('Tarea no encontrada');
      } else {
        _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Error de conexión: $e');
    }
  }

  /// Verifica la salud de la API
  Future<bool> healthCheck() async {
    try {
      final response = await client
          .get(
            Uri.parse('${ApiConstants.baseUrl}/tasks'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode < 500;
    } catch (e) {
      return false;
    }
  }
}
