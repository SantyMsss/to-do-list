import '../../domain/entities/task.dart';
import '../../core/utils/date_utils.dart';

/// Modelo de datos para Task con conversión JSON y SQLite
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.completed,
    required super.createdAt,
    required super.updatedAt,
    super.deleted,
  });

  /// Crea un TaskModel desde JSON (API REST)
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      completed: json['completed'] as bool,
      createdAt: DateTimeUtils.fromIso8601(json['created_at'] as String?) 
          ?? DateTimeUtils.now(),
      updatedAt: DateTimeUtils.fromIso8601(json['updated_at'] as String?) 
          ?? DateTimeUtils.now(),
      deleted: false,
    );
  }

  /// Convierte el modelo a JSON para enviar a la API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'created_at': DateTimeUtils.toIso8601(createdAt),
      'updated_at': DateTimeUtils.toIso8601(updatedAt),
    };
  }

  /// Crea un TaskModel desde la base de datos SQLite
  factory TaskModel.fromDatabase(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTimeUtils.fromIso8601(map['created_at'] as String?) 
          ?? DateTimeUtils.now(),
      updatedAt: DateTimeUtils.fromIso8601(map['updated_at'] as String?) 
          ?? DateTimeUtils.now(),
      deleted: (map['deleted'] as int) == 1,
    );
  }

  /// Convierte el modelo a Map para guardar en SQLite
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
      'created_at': DateTimeUtils.toIso8601(createdAt),
      'updated_at': DateTimeUtils.toIso8601(updatedAt),
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Crea un TaskModel desde una entidad Task
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      completed: task.completed,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      deleted: task.deleted,
    );
  }

  /// Convierte el modelo a entidad Task
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      completed: completed,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deleted: deleted,
    );
  }

  @override
  TaskModel copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}
