import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/task_form_dialog.dart';
import '../widgets/filter_chip_row.dart';

/// Pantalla principal que muestra la lista de tareas
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool? _currentFilter;

  @override
  void initState() {
    super.initState();
    // Cargar tareas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
      _syncIfPossible();
    });
  }

  Future<void> _syncIfPossible() async {
    final provider = context.read<TaskProvider>();
    if (await provider.checkConnection()) {
      await provider.syncPendingOperations();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<TaskProvider>().refreshTasks();
    await _syncIfPossible();
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        onSubmit: (title) async {
          final success = await context.read<TaskProvider>().createTask(title);
          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Tarea creada exitosamente'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF10B981),
                action: SnackBarAction(
                  label: 'Ver',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _applyFilter(bool? filter) {
    setState(() {
      _currentFilter = filter;
    });
    context.read<TaskProvider>().fetchTasks(completed: filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          Consumer<TaskProvider>(
            builder: (context, provider, _) {
              return FutureBuilder<bool>(
                future: provider.checkConnection(),
                builder: (context, snapshot) {
                  final hasConnection = snapshot.data ?? false;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: hasConnection 
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFF94A3B8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        hasConnection ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: hasConnection 
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                      onPressed: () async {
                        if (hasConnection) {
                          await provider.syncPendingOperations();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Sincronización completada'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Sin conexión a internet'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFFF59E0B),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          FilterChipRow(
            currentFilter: _currentFilter,
            onFilterChanged: _applyFilter,
          ),
          
          // Estadísticas
          Consumer<TaskProvider>(
            builder: (context, provider, _) {
              final stats = provider.getStatistics();
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total', stats['total']!, Colors.white),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItem('Pendientes', stats['pending']!, Colors.white),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItem('Completadas', stats['completed']!, Colors.white),
                  ],
                ),
              );
            },
          ),
          
          const Divider(height: 1),
          
          // Lista de tareas
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.tasks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage ?? 'Error desconocido',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.refreshTasks(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.task_alt_rounded,
                            size: 80,
                            color: const Color(0xFF6366F1).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No hay tareas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Presiona el botón + para agregar una',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    itemCount: provider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = provider.tasks[index];
                      return TaskItem(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: () => provider.toggleTaskCompletion(task),
                        onDelete: () => _confirmDelete(task.id),
                        onEdit: () => _showEditDialog(task.id, task.title),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddTaskDialog,
          tooltip: 'Agregar Tarea',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_rounded,
            color: Color(0xFFEF4444),
            size: 32,
          ),
        ),
        title: const Text(
          'Eliminar tarea',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta tarea? Esta acción no se puede deshacer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<TaskProvider>().deleteTask(taskId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarea eliminada'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showEditDialog(String taskId, String currentTitle) {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(
        initialTitle: currentTitle,
        title: 'Editar Tarea',
        onSubmit: (newTitle) async {
          final task = context
              .read<TaskProvider>()
              .tasks
              .firstWhere((t) => t.id == taskId);
          
          final updatedTask = task.copyWith(title: newTitle);
          final success = await context.read<TaskProvider>().updateTask(updatedTask);
          
          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Tarea actualizada'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF6366F1),
              ),
            );
          }
        },
      ),
    );
  }
}
