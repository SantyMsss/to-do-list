import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/datasources/local_data_source.dart';
import 'data/datasources/remote_data_source.dart';
import 'data/repositories/task_repository_impl.dart';
import 'presentation/providers/task_provider.dart';
import 'presentation/screens/task_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configuración de datasources y repository
    final localDataSource = LocalDataSource();
    final remoteDataSource = RemoteDataSource();
    final taskRepository = TaskRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );

    return MultiProvider(
      providers: [
        // Provider del repositorio (si otros providers lo necesitan)
        Provider.value(value: taskRepository),
        
        // ChangeNotifierProvider para el estado de tareas
        ChangeNotifierProvider(
          create: (_) => TaskProvider(repository: taskRepository),
        ),
      ],
      child: MaterialApp(
        title: 'To-Do List',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Indigo moderno
            brightness: Brightness.light,
            primary: const Color(0xFF6366F1),
            secondary: const Color(0xFF8B5CF6),
            surface: Colors.white,
            background: const Color(0xFFF8FAFC),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF1E293B),
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            iconSize: 28,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFF1F5F9),
            selectedColor: const Color(0xFF6366F1).withOpacity(0.15),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const TaskListScreen(),
      ),
    );
  }
}