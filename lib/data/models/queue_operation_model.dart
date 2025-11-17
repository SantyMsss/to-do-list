/// Operaciones de sincronización pendientes
enum OperationType {
  create,
  update,
  delete;

  String toDatabase() => name.toUpperCase();

  static OperationType fromDatabase(String value) {
    return OperationType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => OperationType.create,
    );
  }
}

/// Modelo para la cola de operaciones pendientes
class QueueOperation {
  final String id;
  final String entity;
  final String entityId;
  final OperationType operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attemptCount;
  final String? lastError;

  const QueueOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
  });

  /// Crea desde la base de datos
  factory QueueOperation.fromDatabase(Map<String, dynamic> map) {
    return QueueOperation(
      id: map['id'] as String,
      entity: map['entity'] as String,
      entityId: map['entity_id'] as String,
      operation: OperationType.fromDatabase(map['op'] as String),
      payload: map['payload'] != null 
          ? _decodePayload(map['payload'] as String)
          : {},
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      attemptCount: map['attempt_count'] as int,
      lastError: map['last_error'] as String?,
    );
  }

  /// Convierte a Map para la base de datos
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'entity': entity,
      'entity_id': entityId,
      'op': operation.toDatabase(),
      'payload': _encodePayload(payload),
      'created_at': createdAt.millisecondsSinceEpoch,
      'attempt_count': attemptCount,
      'last_error': lastError,
    };
  }

  /// Crea una copia con campos modificados
  QueueOperation copyWith({
    String? id,
    String? entity,
    String? entityId,
    OperationType? operation,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? attemptCount,
    String? lastError,
  }) {
    return QueueOperation(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
    );
  }

  static String _encodePayload(Map<String, dynamic> payload) {
    // Convierte el payload a una cadena JSON simple
    final entries = payload.entries.map((e) => '"${e.key}":"${e.value}"');
    return '{${entries.join(',')}}';
  }

  static Map<String, dynamic> _decodePayload(String payloadString) {
    // Decodifica la cadena JSON simple
    final cleaned = payloadString.replaceAll('{', '').replaceAll('}', '');
    if (cleaned.isEmpty) return {};
    
    final Map<String, dynamic> result = {};
    final pairs = cleaned.split(',');
    
    for (final pair in pairs) {
      final keyValue = pair.split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0].replaceAll('"', '').trim();
        final value = keyValue[1].replaceAll('"', '').trim();
        result[key] = value;
      }
    }
    
    return result;
  }

  @override
  String toString() {
    return 'QueueOperation(id: $id, operation: $operation, entityId: $entityId, attempts: $attemptCount)';
  }
}
