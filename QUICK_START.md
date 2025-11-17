# Guía Rápida de Inicio

## 🚀 Pasos para ejecutar la aplicación

### 1. Configurar el Backend (API REST)

Antes de ejecutar la app Flutter, asegúrate de que tu backend FastAPI esté corriendo:

```bash
cd ../todo-service  # Ajusta la ruta según tu estructura
python main.py
```

El backend debería estar disponible en `http://localhost:8000`

### 2. Configurar la URL de la API

Abre el archivo `lib/core/constants/api_constants.dart` y actualiza la URL base:

**Para Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

**Para iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8000';
```

**Para Dispositivo Físico:**
1. Obtén tu IP local:
   - Windows: `ipconfig` (busca IPv4)
   - Mac/Linux: `ifconfig` o `ip addr`
2. Actualiza la URL:
```dart
static const String baseUrl = 'http://TU_IP_LOCAL:8000';
```
Ejemplo: `http://192.168.1.100:8000`

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Ejecutar la aplicación

```bash
flutter run
```

Si tienes múltiples dispositivos conectados:
```bash
flutter devices  # Ver dispositivos disponibles
flutter run -d <device-id>  # Ejecutar en dispositivo específico
```

## 🧪 Probar la Aplicación

### Caso 1: Modo Online (Con Internet)

1. Asegúrate de que el backend esté corriendo
2. Abre la app
3. Crea algunas tareas
4. Verifica que el ícono de nube esté en verde ☁️✅
5. Las tareas se guardan localmente Y se sincronizan con el servidor

### Caso 2: Modo Offline (Sin Internet)

1. Cierra el backend o activa modo avión
2. Abre la app
3. Crea, edita y elimina tareas
4. El ícono de nube estará en gris ☁️⚫
5. Todo funciona localmente
6. Reactiva la conexión
7. Presiona el ícono de nube para sincronizar
8. ¡Los cambios se envían al servidor!

### Caso 3: Sincronización Automática

1. Con la app abierta y conectada
2. Crea una tarea desde el backend usando:
```bash
curl -X POST "http://localhost:8000/tasks" \
  -H "Content-Type: application/json" \
  -d '{"title":"Tarea desde API","completed":false}'
```
3. En la app, desliza hacia abajo (pull-to-refresh)
4. La nueva tarea aparecerá en la lista

## 🎯 Funcionalidades a Probar

### Crear Tarea
- Presiona el botón flotante `+`
- Ingresa un título
- Presiona "Guardar"

### Marcar como Completada
- Desliza la tarea hacia la derecha →
- O marca el checkbox

### Editar Tarea
- Toca el menú de 3 puntos (⋮)
- Selecciona "Editar"
- Cambia el título
- Guarda

### Eliminar Tarea
- Desliza la tarea hacia la izquierda ←
- O usa el menú de 3 puntos → "Eliminar"
- Confirma la eliminación

### Filtrar Tareas
- Usa los chips en la parte superior:
  - **Todas**: Muestra todas las tareas
  - **Pendientes**: Solo no completadas
  - **Completadas**: Solo completadas

### Estadísticas
Observa los contadores en la parte superior:
- **Total**: Número total de tareas
- **Pendientes**: Tareas sin completar
- **Completadas**: Tareas terminadas

## 🔍 Verificar Sincronización

### Desde la App al Backend
1. Crea una tarea en la app
2. Consulta el backend:
```bash
curl http://localhost:8000/tasks
```
3. Deberías ver la tarea creada

### Desde el Backend a la App
1. Crea una tarea en el backend:
```bash
curl -X POST "http://localhost:8000/tasks" \
  -H "Content-Type: application/json" \
  -d '{"title":"Tarea de prueba","completed":false}'
```
2. Haz pull-to-refresh en la app
3. La tarea aparecerá

## ⚠️ Problemas Comunes

### ❌ "No se puede conectar al servidor"
**Solución:**
- Verifica que el backend esté corriendo
- Revisa la URL en `api_constants.dart`
- Si usas emulador Android, usa `10.0.2.2` en lugar de `localhost`

### ❌ "Las tareas no se sincronizan"
**Solución:**
- Verifica el indicador de conexión (ícono de nube)
- Presiona el ícono de nube para forzar sincronización
- Revisa los logs de Flutter: `flutter logs`

### ❌ "Error de compilación"
**Solución:**
```bash
flutter clean
flutter pub get
flutter run
```

### ❌ "Cannot find device"
**Solución:**
```bash
flutter doctor  # Ver qué falta
flutter devices # Ver dispositivos conectados
```

## 📱 Dispositivos Recomendados para Pruebas

### Android
```bash
# Crear emulador Android
flutter emulator --create --name android_test
# Ejecutar emulador
flutter emulator --launch android_test
# Ejecutar app
flutter run
```

### iOS (Solo en Mac)
```bash
# Listar simuladores
xcrun simctl list devices
# Ejecutar simulador
open -a Simulator
# Ejecutar app
flutter run
```

### Chrome (Para desarrollo web)
```bash
flutter run -d chrome
```

## 🎓 Próximos Pasos

1. ✅ Familiarízate con la estructura del código
2. ✅ Prueba todos los casos de uso
3. ✅ Experimenta con el modo offline
4. ✅ Revisa los logs para entender el flujo
5. ✅ Modifica la UI según tus preferencias

## 📚 Archivos Importantes

- `lib/main.dart` - Punto de entrada
- `lib/core/constants/api_constants.dart` - Configuración API
- `lib/presentation/screens/task_list_screen.dart` - Pantalla principal
- `lib/data/repositories/task_repository_impl.dart` - Lógica de sincronización
- `lib/presentation/providers/task_provider.dart` - Gestión de estado

## 🆘 Ayuda Adicional

Si encuentras problemas:
1. Lee los mensajes de error en la consola
2. Ejecuta `flutter doctor` para ver el estado del entorno
3. Revisa los logs: `flutter logs`
4. Consulta la documentación en `README_APP.md`

---

**¡Listo! Ahora puedes empezar a probar la aplicación** 🎉
