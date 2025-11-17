# 📝 Documentación Técnica - To-Do List App

## 🎯 Cumplimiento de Requisitos del Taller

### ✅ Requisitos Implementados

#### 1. Framework y Versión
- [x] Flutter 3.x
- [x] Dart 3.10+

#### 2. Gestión de Estado
- [x] Provider implementado
- [x] Estados definidos: `initial`, `loading`, `loaded`, `error`
- [x] ChangeNotifier para reactividad

#### 3. Arquitectura Limpia
- [x] **Domain Layer**: Entidades y contratos de repositorio
- [x] **Data Layer**: Datasources (local/remote), modelos, implementación de repositorio
- [x] **Presentation Layer**: Providers, screens, widgets

#### 4. Integración con API REST
- [x] Cliente HTTP configurado
- [x] Todos los endpoints consumidos:
  - GET `/tasks` - Listar tareas
  - GET `/tasks?completed=true/false` - Filtrar tareas
  - GET `/tasks/{id}` - Obtener una tarea
  - POST `/tasks` - Crear tarea
  - PUT `/tasks/{id}` - Actualizar tarea
  - DELETE `/tasks/{id}` - Eliminar tarea

#### 5. Persistencia Local (SQLite)
- [x] Paquete `sqflite` implementado
- [x] Tabla `tasks` con campos requeridos
- [x] Tabla `queue_operations` para sincronización
- [x] Índices para optimización

#### 6. Modo Offline-First
- [x] **Lecturas**: Datos locales primero, sync en segundo plano
- [x] **Escrituras**: Guardar local y encolar para sync
- [x] Cola de operaciones pendientes

#### 7. Sincronización
- [x] Detección de conectividad con `connectivity_plus`
- [x] Sincronización automática al recuperar conexión
- [x] Reintentos con backoff exponencial
- [x] Resolución de conflictos (Last-Write-Wins)

#### 8. Manejo de Errores
- [x] Timeouts configurados (10 segundos)
- [x] Manejo de errores 4xx y 5xx
- [x] Mensajes claros para el usuario
- [x] Clases de error personalizadas (`Failure`)

#### 9. Buenas Prácticas
- [x] Documentación en código
- [x] Control de versiones (Git ready)
- [x] Nombres descriptivos
- [x] Separación de responsabilidades
- [x] README completo

---

## 📊 Estructura de Datos

### Entidad Task (Domain)
```dart
class Task {
  final String id;           // UUID generado localmente
  final String title;        // Título de la tarea
  final bool completed;      // Estado de completitud
  final DateTime createdAt;  // Fecha de creación (UTC)
  final DateTime updatedAt;  // Fecha de última actualización (UTC)
  final bool deleted;        // Soft delete flag
}
```

### Formato de API (JSON)
```json
{
  "id": 1,
  "title": "Completar proyecto Flutter",
  "completed": false,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

### Formato en SQLite
```sql
id: TEXT (UUID)
title: TEXT
completed: INTEGER (0 o 1)
created_at: TEXT (ISO8601)
updated_at: TEXT (ISO8601)
deleted: INTEGER (0 o 1)
```

---

## 🔄 Flujos de Datos

### Flujo de Creación de Tarea

```
Usuario presiona "+" 
    ↓
TaskFormDialog muestra formulario
    ↓
Usuario ingresa título y presiona "Guardar"
    ↓
TaskProvider.createTask(title)
    ↓
TaskRepository.createTask(title)
    ↓
1. Genera UUID único
2. Crea TaskModel con timestamps
3. Guarda en SQLite (LocalDataSource)
4. Encola operación (QueueOperation)
5. Si hay internet, ejecuta syncPendingOperations()
    ↓
RemoteDataSource.createTask()
    ↓
POST /tasks con Idempotency-Key
    ↓
Si éxito:
  - Elimina de cola
  - Actualiza ID local con ID del servidor
Si falla:
  - Incrementa attempt_count
  - Guarda last_error
  - Reintenta después
    ↓
UI se actualiza automáticamente (Provider)
```

### Flujo de Lectura de Tareas

```
Usuario abre la app
    ↓
TaskProvider.fetchTasks()
    ↓
TaskRepository.getTasks()
    ↓
1. Lee de SQLite (LocalDataSource)
2. Retorna inmediatamente a la UI
3. Si hay internet, ejecuta _syncTasksInBackground()
    ↓
_syncTasksInBackground():
  - GET /tasks desde API
  - Para cada tarea del servidor:
    * Si no existe localmente → INSERT
    * Si existe localmente:
      - Compara updated_at
      - Si servidor > local → UPDATE local
      - Si local > servidor → mantener local
    ↓
Provider notifica a la UI
    ↓
UI se actualiza con datos sincronizados
```

### Flujo de Sincronización (Conectividad Recuperada)

```
App detecta conexión
    ↓
TaskProvider.syncPendingOperations()
    ↓
TaskRepository.syncPendingOperations()
    ↓
1. LocalDataSource.getPendingOperations()
2. Para cada operación:
    ↓
    Según tipo de operación:
    
    CREATE:
      - POST /tasks con idempotency_key
      - Actualiza ID local con ID servidor
      - Elimina de cola
    
    UPDATE:
      - PUT /tasks/{id}
      - Elimina de cola
    
    DELETE:
      - DELETE /tasks/{id}
      - Hard delete local
      - Elimina de cola
    
    Si falla:
      - attempt_count++
      - Guarda last_error
      - Si attempt_count > 5 → elimina de cola
    ↓
3. cleanOldOperations() - Limpia operaciones > 7 días
    ↓
UI actualizada
```

---

## 🧩 Componentes Clave

### 1. LocalDataSource (SQLite)
**Responsabilidad**: Persistencia local

```dart
// Operaciones principales
getTasks({bool? completed})        // Leer tareas con filtro
getTaskById(String id)             // Leer una tarea
insertTask(TaskModel task)         // Insertar tarea
updateTask(TaskModel task)         // Actualizar tarea
deleteTask(String id)              // Soft delete
hardDeleteTask(String id)          // Hard delete

// Cola de sincronización
enqueueOperation(QueueOperation)   // Encolar operación
getPendingOperations()             // Obtener pendientes
removeOperation(String id)         // Eliminar de cola
updateOperationAttempt(...)        // Actualizar intentos
cleanOldOperations()               // Limpiar antiguas
```

### 2. RemoteDataSource (HTTP)
**Responsabilidad**: Comunicación con API REST

```dart
getTasks({bool? completed})        // GET /tasks
getTaskById(String id)             // GET /tasks/{id}
createTask({title, idempotencyKey}) // POST /tasks
updateTask({id, title, completed})  // PUT /tasks/{id}
deleteTask(String id)              // DELETE /tasks/{id}
healthCheck()                      // Verificar API
```

### 3. TaskRepositoryImpl
**Responsabilidad**: Orquestación offline-first y sincronización

**Estrategia**:
- Lee local primero (rápido)
- Sincroniza en segundo plano (sin bloquear UI)
- Encola cambios para sincronizar después
- Resuelve conflictos con LWW

### 4. TaskProvider (ChangeNotifier)
**Responsabilidad**: Gestión de estado reactivo

**Estados**:
- `initial`: Estado inicial
- `loading`: Cargando datos
- `loaded`: Datos cargados exitosamente
- `error`: Error ocurrido

**Métodos públicos**:
```dart
fetchTasks({bool? completed})      // Cargar tareas
refreshTasks()                     // Refrescar
createTask(String title)           // Crear
updateTask(Task task)              // Actualizar
toggleTaskCompletion(Task task)    // Toggle completado
deleteTask(String id)              // Eliminar
syncPendingOperations()            // Sincronizar
checkConnection()                  // Verificar conexión
```

---

## 🔐 Manejo de Idempotencia

Para evitar crear tareas duplicadas al reintentar:

```dart
// Al crear tarea, se genera un UUID
final operationId = uuid.v4();

// Se envía como header
headers: {
  'Idempotency-Key': operationId
}

// El servidor FastAPI lo usa para detectar duplicados
```

Si la misma operación se reintenta con el mismo `Idempotency-Key`, el servidor retorna la misma respuesta sin crear duplicado.

---

## ⚡ Optimizaciones Implementadas

### 1. Índices en SQLite
```sql
CREATE INDEX idx_tasks_completed ON tasks (completed);
CREATE INDEX idx_tasks_deleted ON tasks (deleted);
CREATE INDEX idx_queue_entity ON queue_operations (entity, entity_id);
```

### 2. Singleton de Base de Datos
Solo se crea una instancia de la BD durante toda la vida de la app.

### 3. Operaciones en Segundo Plano
Las sincronizaciones no bloquean la UI:
```dart
_syncTasksInBackground({bool? completed}) async {
  try {
    // ... sincronización ...
  } catch (e) {
    // No lanzamos error para no interrumpir UX
    print('Error en sincronización de fondo: $e');
  }
}
```

### 4. Timeouts Configurados
```dart
static const Duration connectionTimeout = Duration(seconds: 10);
```

### 5. Soft Delete
Las tareas no se eliminan de SQLite inmediatamente:
```dart
await db.update(
  _tasksTable,
  {'deleted': 1},  // Solo marca como eliminada
  where: 'id = ?',
  whereArgs: [id],
);
```

---

## 🧪 Casos de Prueba

### Caso 1: Crear tarea sin conexión
1. Activa modo avión
2. Crea tarea "Comprar pan"
3. Verifica que aparece en la lista
4. Verifica en SQLite: `SELECT * FROM tasks WHERE title = 'Comprar pan'`
5. Verifica en cola: `SELECT * FROM queue_operations WHERE op = 'CREATE'`
6. Desactiva modo avión
7. Presiona sincronizar
8. Verifica que la tarea existe en el servidor

### Caso 2: Editar tarea con conexión
1. Crea tarea "Estudiar Flutter"
2. Edita a "Estudiar Flutter y Dart"
3. Verifica cambio inmediato en UI
4. Verifica en servidor: `curl http://localhost:8000/tasks`

### Caso 3: Conflicto de sincronización
1. Crea tarea en app: "Tarea App" (sin conexión)
2. Crea tarea en servidor con mismo ID: "Tarea Server"
3. Conecta la app
4. Sincroniza
5. Verifica que prevalece la de updatedAt más reciente

### Caso 4: Reintento fallido
1. Apaga el servidor
2. Crea tarea en app
3. Conecta internet
4. Verifica que intenta sincronizar
5. Verifica attempt_count en queue_operations
6. Enciende servidor
7. Verifica sincronización exitosa

---

## 📈 Mejoras Futuras Posibles

1. **Paginación**: Para manejar miles de tareas
2. **Búsqueda**: Buscar tareas por título
3. **Categorías**: Organizar tareas por categorías
4. **Recordatorios**: Notificaciones push
5. **Compartir**: Colaboración entre usuarios
6. **Backup**: Backup en la nube
7. **Modo oscuro**: Tema dark
8. **Analytics**: Estadísticas de productividad
9. **Widget**: Widget de escritorio
10. **Voz**: Crear tareas por voz

---

## 🔍 Debugging

### Ver Base de Datos Local

**Android**:
```bash
adb shell
run-as com.example.app
cd databases
sqlite3 todo_app.db

# Consultas útiles
SELECT * FROM tasks;
SELECT * FROM queue_operations;
```

**iOS**:
```bash
# Buscar en ~/Library/Developer/CoreSimulator/Devices/
```

### Ver Logs de Sincronización
```bash
flutter logs | grep -i sync
```

### Ver Peticiones HTTP
Agrega logs en `RemoteDataSource`:
```dart
print('POST /tasks: ${response.statusCode}');
print('Response body: ${response.body}');
```

---

## 📚 Referencias

- [Flutter Official Docs](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Sqflite Package](https://pub.dev/packages/sqflite)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Offline-First Apps](https://offlinefirst.org/)

---

**Documentación generada para el taller de Flutter - Clean Architecture**
