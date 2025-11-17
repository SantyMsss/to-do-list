import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import '../models/queue_operation_model.dart';

/// DataSource local usando SQLite para persistencia offline
class LocalDataSource {
  static Database? _database;
  static const String _databaseName = 'todo_app.db';
  static const int _databaseVersion = 1;

  // Nombres de tablas
  static const String _tasksTable = 'tasks';
  static const String _queueTable = 'queue_operations';

  /// Obtiene la instancia de la base de datos (Singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crea las tablas en la primera ejecución
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de tareas
    await db.execute('''
      CREATE TABLE $_tasksTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabla de cola de sincronización
    await db.execute('''
      CREATE TABLE $_queueTable (
        id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT,
        created_at INTEGER NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Índices para mejorar rendimiento
    await db.execute(
        'CREATE INDEX idx_tasks_completed ON $_tasksTable (completed)');
    await db.execute(
        'CREATE INDEX idx_tasks_deleted ON $_tasksTable (deleted)');
    await db.execute(
        'CREATE INDEX idx_queue_entity ON $_queueTable (entity, entity_id)');
  }

  /// Maneja actualizaciones de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Aquí se manejarían migraciones futuras
  }

  // ==================== OPERACIONES DE TAREAS ====================

  /// Obtiene todas las tareas (excluye eliminadas)
  Future<List<TaskModel>> getTasks({bool? completed}) async {
    final db = await database;
    
    String whereClause = 'deleted = 0';
    List<dynamic> whereArgs = [];
    
    if (completed != null) {
      whereClause += ' AND completed = ?';
      whereArgs.add(completed ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTable,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => TaskModel.fromDatabase(map)).toList();
  }

  /// Obtiene una tarea por ID
  Future<TaskModel?> getTaskById(String id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTable,
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return TaskModel.fromDatabase(maps.first);
  }

  /// Inserta una nueva tarea
  Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert(
      _tasksTable,
      task.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualiza una tarea existente
  Future<void> updateTask(TaskModel task) async {
    final db = await database;
    await db.update(
      _tasksTable,
      task.toDatabase(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Elimina una tarea (soft delete)
  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.update(
      _tasksTable,
      {'deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina permanentemente una tarea
  Future<void> hardDeleteTask(String id) async {
    final db = await database;
    await db.delete(
      _tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== OPERACIONES DE COLA ====================

  /// Encola una operación para sincronización
  Future<void> enqueueOperation(QueueOperation operation) async {
    final db = await database;
    await db.insert(
      _queueTable,
      operation.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las operaciones pendientes
  Future<List<QueueOperation>> getPendingOperations() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _queueTable,
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => QueueOperation.fromDatabase(map)).toList();
  }

  /// Elimina una operación de la cola
  Future<void> removeOperation(String id) async {
    final db = await database;
    await db.delete(
      _queueTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza el conteo de intentos de una operación
  Future<void> updateOperationAttempt(
      String id, int attemptCount, String? error) async {
    final db = await database;
    await db.update(
      _queueTable,
      {
        'attempt_count': attemptCount,
        'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Limpia operaciones antiguas (más de 7 días y con muchos fallos)
  Future<void> cleanOldOperations() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    
    await db.delete(
      _queueTable,
      where: 'created_at < ? AND attempt_count > ?',
      whereArgs: [sevenDaysAgo, 10],
    );
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
