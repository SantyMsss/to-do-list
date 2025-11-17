/// Constantes de configuración para la API REST
class ApiConstants {
  // Cambiar esta URL a tu dirección IP local o servidor
  static const String baseUrl = 'https://todo-service-production-c5ef.up.railway.app';
  
  static const String tasksEndpoint = '/tasks';
  
  // Headers
  static const String contentType = 'application/json';
  static const String idempotencyKeyHeader = 'Idempotency-Key';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
