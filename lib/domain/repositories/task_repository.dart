import '../../domain/entities/task.dart';

/// Repositorio abstracto para las operaciones de tareas
/// Define el contrato que debe implementar la capa de datos
abstract class TaskRepository {
  /// Obtiene todas las tareas
  Future<List<Task>> getTasks({bool? completed});
  
  /// Obtiene una tarea por su ID
  Future<Task?> getTaskById(String id);
  
  /// Crea una nueva tarea
  Future<Task> createTask(String title);
  
  /// Actualiza una tarea existente
  Future<Task> updateTask(Task task);
  
  /// Elimina una tarea
  Future<void> deleteTask(String id);
  
  /// Sincroniza las operaciones pendientes con el servidor
  Future<void> syncPendingOperations();
  
  /// Verifica si hay conexión a internet
  Future<bool> hasConnection();
}
