# To-Do List - Flutter App con Arquitectura Limpia

Aplicación móvil Flutter para gestión de tareas con arquitectura limpia, persistencia local SQLite y sincronización con API REST.

## 🏗️ Arquitectura

El proyecto sigue los principios de **Clean Architecture** (Arquitectura Limpia):

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart          # Constantes de configuración de API
│   ├── errors/
│   │   └── failures.dart                # Clases de errores personalizados
│   └── utils/
│       └── date_utils.dart              # Utilidades de manejo de fechas
├── data/
│   ├── datasources/
│   │   ├── local_data_source.dart       # Acceso a SQLite
│   │   └── remote_data_source.dart      # Cliente HTTP para API REST
│   ├── models/
│   │   ├── task_model.dart              # Modelo de datos con conversiones
│   │   └── queue_operation_model.dart   # Modelo de cola de sincronización
│   └── repositories/
│       └── task_repository_impl.dart    # Implementación del repositorio
├── domain/
│   ├── entities/
│   │   └── task.dart                    # Entidad de negocio Task
│   └── repositories/
│       └── task_repository.dart         # Contrato del repositorio
└── presentation/
    ├── providers/
    │   └── task_provider.dart           # Gestión de estado con Provider
    ├── screens/
    │   └── task_list_screen.dart        # Pantalla principal
    └── widgets/
        ├── task_item.dart               # Item de tarea
        ├── task_form_dialog.dart        # Diálogo crear/editar
        └── filter_chip_row.dart         # Filtros de tareas
```

## 🚀 Características Implementadas

### ✅ Funcionalidades Principales
- **CRUD completo** de tareas (Crear, Leer, Actualizar, Eliminar)
- **Filtros** por estado (todas, pendientes, completadas)
- **Estadísticas** en tiempo real (total, pendientes, completadas)
- **Swipe gestures** para marcar completadas o eliminar
- **Pull to refresh** para actualizar datos
- **Indicador de conectividad** en tiempo real

### ✅ Persistencia y Sincronización
- **Offline-First**: Los datos se cargan primero desde SQLite
- **Sincronización en segundo plano** cuando hay conexión
- **Cola de operaciones** para sincronizar cambios pendientes
- **Resolución de conflictos** con estrategia Last-Write-Wins (LWW)
- **Reintentos automáticos** con backoff exponencial
- **Idempotency-Key** para evitar duplicaciones

### ✅ Gestión de Estado
- **Provider** para gestión de estado reactiva
- Estados: `initial`, `loading`, `loaded`, `error`
- Manejo robusto de errores con mensajes claros

## 📋 Requisitos Previos

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Android Studio / VS Code con extensiones de Flutter
- Emulador o dispositivo físico

## 🔧 Configuración

### 1. Clonar el repositorio
```bash
git clone <tu-repositorio>
cd to-do-list
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar la URL del backend

Edita el archivo `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  // Cambiar esta URL a tu servidor backend
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS Simulator
  // static const String baseUrl = 'http://TU_IP:8000'; // Dispositivo físico
  
  static const String tasksEndpoint = '/tasks';
}
```

**Nota importante sobre URLs:**
- **Android Emulator**: Usa `http://10.0.2.2:8000` (apunta al localhost de tu PC)
- **iOS Simulator**: Usa `http://localhost:8000`
- **Dispositivo físico**: Usa tu IP local, ej: `http://192.168.1.100:8000`

### 4. Ejecutar la aplicación

```bash
flutter run
```

## 🧪 Prueba de la Aplicación

### Probar modo Offline

1. Abre la app y crea algunas tareas
2. Activa el modo avión en tu dispositivo
3. Crea, edita y elimina tareas
4. Observa que todo funciona localmente
5. Desactiva el modo avión
6. Presiona el ícono de nube para sincronizar
7. Verifica que los cambios se reflejen en el servidor

### Probar sincronización automática

1. Crea una tarea desde la app
2. Crea una tarea desde el backend (usando curl o Postman)
3. Haz pull-to-refresh en la app
4. Verifica que la tarea del servidor aparece

## 🔌 Integración con Backend

La app está diseñada para funcionar con el backend FastAPI proporcionado.

### Endpoints consumidos

| Método | Endpoint | Uso |
|--------|----------|-----|
| GET | `/tasks` | Obtener todas las tareas |
| GET | `/tasks?completed=true` | Filtrar completadas |
| GET | `/tasks?completed=false` | Filtrar pendientes |
| GET | `/tasks/{id}` | Obtener una tarea |
| POST | `/tasks` | Crear nueva tarea |
| PUT | `/tasks/{id}` | Actualizar tarea |
| DELETE | `/tasks/{id}` | Eliminar tarea |

### Headers especiales

- `Content-Type: application/json`
- `Idempotency-Key: <uuid>` - Para evitar duplicaciones en operaciones CREATE

## 📦 Dependencias Principales

```yaml
dependencies:
  provider: ^6.1.1          # Gestión de estado
  http: ^1.2.0              # Cliente HTTP
  sqflite: ^2.3.2          # Base de datos SQLite
  connectivity_plus: ^5.0.2 # Detección de conectividad
  uuid: ^4.3.3              # Generación de UUIDs
  intl: ^0.19.0             # Formateo de fechas
```

## 🗃️ Base de Datos Local

### Tabla `tasks`
```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0
);
```

### Tabla `queue_operations`
```sql
CREATE TABLE queue_operations (
  id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  op TEXT NOT NULL,               -- CREATE | UPDATE | DELETE
  payload TEXT,
  created_at INTEGER NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT
);
```

## 🎨 Interfaz de Usuario

### Pantalla Principal
- **AppBar**: Título y indicador de conexión
- **Filtros**: Chips para filtrar (Todas, Pendientes, Completadas)
- **Estadísticas**: Contadores visuales
- **Lista**: Tareas con checkbox, título, fecha y menú de opciones
- **FAB**: Botón flotante para agregar nueva tarea

### Gestos Implementados
- **Swipe derecha**: Marcar como completada
- **Swipe izquierda**: Eliminar
- **Long press**: Menú contextual
- **Pull down**: Refrescar datos

## 🔄 Flujo de Sincronización

1. **Lectura (GET)**:
   - Mostrar datos locales inmediatamente
   - Si hay internet, sincronizar en segundo plano
   - Actualizar UI si hay cambios

2. **Escritura (POST/PUT/DELETE)**:
   - Guardar cambio localmente
   - Encolar operación en `queue_operations`
   - Si hay internet, sincronizar inmediatamente
   - Si falla, reintentar automáticamente

3. **Resolución de conflictos**:
   - Comparar `updated_at` del servidor vs local
   - Last-Write-Wins: Gana el más reciente
   - Actualizar registro local si el servidor es más nuevo

## 🐛 Solución de Problemas

### Error: "SocketException: Failed host lookup"
- Verifica que el backend esté ejecutándose
- Revisa la URL en `api_constants.dart`
- Si usas emulador Android, usa `10.0.2.2` en lugar de `localhost`

### Las tareas no se sincronizan
- Verifica el indicador de nube (verde = conectado, gris = desconectado)
- Presiona manualmente el ícono de nube para forzar sincronización
- Revisa la consola de Flutter para ver errores de red

### La app se cierra al abrir
- Ejecuta `flutter clean` y luego `flutter pub get`
- Verifica que todas las dependencias se instalaron correctamente
- Revisa la consola para ver el stack trace del error

## 📚 Recursos Adicionales

- [Documentación del Backend](../todo-service/README.md)
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Sqflite Documentation](https://pub.dev/packages/sqflite)

## 👨‍💻 Desarrollo

### Agregar nuevas características

1. **Nueva entidad**: Crear en `domain/entities/`
2. **Nuevo modelo**: Crear en `data/models/` con conversiones JSON/DB
3. **Nuevo datasource**: Agregar métodos en `data/datasources/`
4. **Nuevo repositorio**: Implementar en `data/repositories/`
5. **Nuevo provider**: Crear en `presentation/providers/`
6. **Nueva pantalla**: Crear en `presentation/screens/`

### Buenas prácticas seguidas

- ✅ Separación de responsabilidades (Clean Architecture)
- ✅ Principio de inversión de dependencias
- ✅ Código reutilizable y mantenible
- ✅ Manejo robusto de errores
- ✅ Comentarios y documentación
- ✅ Nombres descriptivos en variables y funciones

## 📄 Licencia

Este proyecto es parte de una evaluación técnica de desarrollo móvil con Flutter.

---

**Desarrollado con ❤️ usando Flutter y Clean Architecture**
