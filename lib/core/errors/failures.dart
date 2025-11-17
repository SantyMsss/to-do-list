/// Clase base para representar fallos en la aplicación
abstract class Failure {
  final String message;
  
  const Failure(this.message);
  
  @override
  String toString() => message;
}

/// Fallo en la conexión de red
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Error de conexión. Verifica tu internet.'])
      : super(message);
}

/// Fallo en el servidor (5xx)
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Error del servidor. Intenta más tarde.'])
      : super(message);
}

/// Fallo en la solicitud del cliente (4xx)
class ClientFailure extends Failure {
  const ClientFailure([String message = 'Solicitud inválida.'])
      : super(message);
}

/// Fallo en la base de datos local
class DatabaseFailure extends Failure {
  const DatabaseFailure([String message = 'Error en la base de datos local.'])
      : super(message);
}

/// Fallo desconocido
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Error desconocido.'])
      : super(message);
}
