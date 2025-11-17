import 'package:intl/intl.dart';

/// Utilidades para manejo de fechas en formato ISO8601
class DateTimeUtils {
  /// Convierte un String ISO8601 a DateTime
  static DateTime? fromIso8601(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString).toUtc();
    } catch (e) {
      return null;
    }
  }
  
  /// Convierte un DateTime a String ISO8601
  static String toIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }
  
  /// Obtiene la fecha actual en UTC
  static DateTime now() {
    return DateTime.now().toUtc();
  }
  
  /// Formatea una fecha para mostrar al usuario
  static String formatForDisplay(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);
    
    if (difference.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(localDate)}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${DateFormat('HH:mm').format(localDate)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(localDate);
    }
  }
}
