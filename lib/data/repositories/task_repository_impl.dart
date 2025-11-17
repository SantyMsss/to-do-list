import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/date_utils.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';
import '../models/task_model.dart';
import '../models/queue_operation_model.dart';

/// Implementación del repositorio con estrategia Offline-First
class TaskRepositoryImpl implements TaskRepository {
  final LocalDataSource localDataSource;
  final RemoteDataSource remoteDataSource;
  final Connectivity connectivity;
  final Uuid uuid;

  TaskRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    Connectivity? connectivity,
    Uuid? uuid,
  })  : connectivity = connectivity ?? Connectivity(),
        uuid = uuid ?? const Uuid();

  @override
  Future<bool> hasConnection() async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Future<List<Task>> getTasks({bool? completed}) async {
    try {
      // 1. Primero retornamos datos locales (Offline-First)
      final localTasks = await localDataSource.getTasks(completed: completed);

      // 2. Si hay conexión, sincronizamos en segundo plano
      if (await hasConnection()) {
        _syncTasksInBackground(completed: completed);
      }

      return localTasks;
    } catch (e) {
      throw DatabaseFailure('Error obteniendo tareas: $e');
    }
  }

  /// Sincroniza tareas en segundo plano sin bloquear la UI
  Future<void> _syncTasksInBackground({bool? completed}) async {
    try {
      final remoteTasks = await remoteDataSource.getTasks(completed: completed);

      for (final remoteTask in remoteTasks) {
        final localTask = await localDataSource.getTaskById(remoteTask.id);

        if (localTask == null) {
          // Tarea nueva del servidor, guardar localmente
          await localDataSource.insertTask(remoteTask);
        } else {
          // Resolver conflictos con Last-Write-Wins
          if (remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
            await localDataSource.updateTask(remoteTask);
          }
        }
      }
    } catch (e) {
      // No lanzamos error para no interrumpir la experiencia del usuario
      print('Error en sincronización de fondo: $e');
    }
  }

  @override
  Future<Task?> getTaskById(String id) async {
    try {
      // Intentar obtener de local primero
      final localTask = await localDataSource.getTaskById(id);

      if (localTask != null) {
        return localTask;
      }

      // Si no está en local y hay conexión, buscar en remoto
      if (await hasConnection()) {
        final remoteTask = await remoteDataSource.getTaskById(id);
        if (remoteTask != null) {
          await localDataSource.insertTask(remoteTask);
          return remoteTask;
        }
      }

      return null;
    } catch (e) {
      throw DatabaseFailure('Error obteniendo tarea: $e');
    }
  }

  @override
  Future<Task> createTask(String title) async {
    final taskId = uuid.v4();
    final now = DateTimeUtils.now();

    final task = TaskModel(
      id: taskId,
      title: title,
      completed: false,
      createdAt: now,
      updatedAt: now,
    );

    try {
      // 1. Guardar localmente primero
      await localDataSource.insertTask(task);

      // 2. Encolar operación para sincronización
      await _enqueueOperation(
        operation: OperationType.create,
        entityId: taskId,
        payload: {'title': title},
      );

      // 3. Si hay conexión, sincronizar inmediatamente
      if (await hasConnection()) {
        await syncPendingOperations();
      }

      return task;
    } catch (e) {
      throw DatabaseFailure('Error creando tarea: $e');
    }
  }

  @override
  Future<Task> updateTask(Task task) async {
    final updatedTask = TaskModel.fromEntity(task).copyWith(
      updatedAt: DateTimeUtils.now(),
    );

    try {
      // 1. Actualizar localmente
      await localDataSource.updateTask(updatedTask);

      // 2. Encolar operación
      await _enqueueOperation(
        operation: OperationType.update,
        entityId: task.id,
        payload: {
          'title': task.title,
          'completed': task.completed.toString(),
        },
      );

      // 3. Sincronizar si hay conexión
      if (await hasConnection()) {
        await syncPendingOperations();
      }

      return updatedTask;
    } catch (e) {
      throw DatabaseFailure('Error actualizando tarea: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      // 1. Marcar como eliminada localmente (soft delete)
      await localDataSource.deleteTask(id);

      // 2. Encolar operación
      await _enqueueOperation(
        operation: OperationType.delete,
        entityId: id,
        payload: {},
      );

      // 3. Sincronizar si hay conexión
      if (await hasConnection()) {
        await syncPendingOperations();
      }
    } catch (e) {
      throw DatabaseFailure('Error eliminando tarea: $e');
    }
  }

  /// Encola una operación para sincronización posterior
  Future<void> _enqueueOperation({
    required OperationType operation,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final queueOperation = QueueOperation(
      id: uuid.v4(),
      entity: 'task',
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now(),
    );

    await localDataSource.enqueueOperation(queueOperation);
  }

  @override
  Future<void> syncPendingOperations() async {
    if (!await hasConnection()) {
      return; // Sin conexión, no hacer nada
    }

    try {
      final operations = await localDataSource.getPendingOperations();

      for (final operation in operations) {
        try {
          await _executeOperation(operation);
          // Si tiene éxito, eliminar de la cola
          await localDataSource.removeOperation(operation.id);
        } catch (e) {
          // Si falla, incrementar contador de intentos
          await localDataSource.updateOperationAttempt(
            operation.id,
            operation.attemptCount + 1,
            e.toString(),
          );

          // Si ha fallado muchas veces, eliminarla
          if (operation.attemptCount >= 5) {
            await localDataSource.removeOperation(operation.id);
          }
        }
      }

      // Limpiar operaciones antiguas
      await localDataSource.cleanOldOperations();
    } catch (e) {
      print('Error en sincronización: $e');
    }
  }

  /// Ejecuta una operación específica contra la API
  Future<void> _executeOperation(QueueOperation operation) async {
    switch (operation.operation) {
      case OperationType.create:
        final title = operation.payload['title'] as String;
        final remoteTask = await remoteDataSource.createTask(
          title: title,
          idempotencyKey: operation.id,
        );
        
        // Actualizar ID local con el del servidor
        final localTask = await localDataSource.getTaskById(operation.entityId);
        if (localTask != null) {
          await localDataSource.hardDeleteTask(operation.entityId);
          await localDataSource.insertTask(remoteTask);
        }
        break;

      case OperationType.update:
        final title = operation.payload['title'] as String?;
        final completed = operation.payload['completed'] == 'true';
        
        await remoteDataSource.updateTask(
          id: operation.entityId,
          title: title,
          completed: completed,
        );
        break;

      case OperationType.delete:
        await remoteDataSource.deleteTask(operation.entityId);
        // Eliminar permanentemente de local
        await localDataSource.hardDeleteTask(operation.entityId);
        break;
    }
  }
}
