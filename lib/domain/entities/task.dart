/// Entidad de dominio para una Tarea
/// Esta es la representación pura de negocio, sin dependencias externas
class Task {
  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  const Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  /// Crea una copia de la tarea con los campos especificados modificados
  Task copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, completed: $completed)';
  }
}
