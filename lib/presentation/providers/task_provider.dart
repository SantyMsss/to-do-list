import 'package:flutter/foundation.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../core/errors/failures.dart';

/// Estados posibles del provider
enum TaskState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider para gestión de estado de tareas usando Provider
class TaskProvider extends ChangeNotifier {
  final TaskRepository repository;

  TaskProvider({required this.repository});

  // Estado
  TaskState _state = TaskState.initial;
  List<Task> _tasks = [];
  String? _errorMessage;
  bool? _currentFilter;

  // Getters
  TaskState get state => _state;
  List<Task> get tasks => _tasks;
  String? get errorMessage => _errorMessage;
  bool get hasError => _state == TaskState.error;
  bool get isLoading => _state == TaskState.loading;
  bool get isEmpty => _tasks.isEmpty && _state == TaskState.loaded;

  /// Obtiene todas las tareas con filtro opcional
  Future<void> fetchTasks({bool? completed}) async {
    _currentFilter = completed;
    _setState(TaskState.loading);

    try {
      final fetchedTasks = await repository.getTasks(completed: completed);
      _tasks = fetchedTasks;
      _errorMessage = null;
      _setState(TaskState.loaded);
    } on Failure catch (failure) {
      _errorMessage = failure.message;
      _setState(TaskState.error);
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(TaskState.error);
    }
  }

  /// Refresca las tareas (mantiene el filtro actual)
  Future<void> refreshTasks() async {
    await fetchTasks(completed: _currentFilter);
  }

  /// Crea una nueva tarea
  Future<bool> createTask(String title) async {
    if (title.trim().isEmpty) {
      _errorMessage = 'El título no puede estar vacío';
      _setState(TaskState.error);
      return false;
    }

    try {
      final newTask = await repository.createTask(title.trim());
      
      // Agregar la nueva tarea a la lista actual
      _tasks.insert(0, newTask);
      notifyListeners();
      
      return true;
    } on Failure catch (failure) {
      _errorMessage = failure.message;
      _setState(TaskState.error);
      return false;
    } catch (e) {
      _errorMessage = 'Error creando tarea: $e';
      _setState(TaskState.error);
      return false;
    }
  }

  /// Actualiza una tarea existente
  Future<bool> updateTask(Task task) async {
    try {
      final updatedTask = await repository.updateTask(task);
      
      // Actualizar en la lista
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      
      return true;
    } on Failure catch (failure) {
      _errorMessage = failure.message;
      _setState(TaskState.error);
      return false;
    } catch (e) {
      _errorMessage = 'Error actualizando tarea: $e';
      _setState(TaskState.error);
      return false;
    }
  }

  /// Marca/desmarca una tarea como completada
  Future<bool> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(completed: !task.completed);
    return await updateTask(updatedTask);
  }

  /// Elimina una tarea
  Future<bool> deleteTask(String taskId) async {
    try {
      await repository.deleteTask(taskId);
      
      // Eliminar de la lista
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
      
      return true;
    } on Failure catch (failure) {
      _errorMessage = failure.message;
      _setState(TaskState.error);
      return false;
    } catch (e) {
      _errorMessage = 'Error eliminando tarea: $e';
      _setState(TaskState.error);
      return false;
    }
  }

  /// Sincroniza operaciones pendientes
  Future<void> syncPendingOperations() async {
    try {
      await repository.syncPendingOperations();
      // Refrescar después de sincronizar
      await refreshTasks();
    } catch (e) {
      print('Error sincronizando: $e');
    }
  }

  /// Verifica si hay conexión
  Future<bool> checkConnection() async {
    try {
      return await repository.hasConnection();
    } catch (e) {
      return false;
    }
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    if (_state == TaskState.error) {
      _setState(TaskState.loaded);
    }
  }

  /// Filtra tareas por estado de completado
  List<Task> getFilteredTasks({bool? completed}) {
    if (completed == null) return _tasks;
    return _tasks.where((task) => task.completed == completed).toList();
  }

  /// Obtiene estadísticas de tareas
  Map<String, int> getStatistics() {
    return {
      'total': _tasks.length,
      'completed': _tasks.where((task) => task.completed).length,
      'pending': _tasks.where((task) => !task.completed).length,
    };
  }

  void _setState(TaskState newState) {
    _state = newState;
    notifyListeners();
  }
}
