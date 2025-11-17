import 'package:flutter/material.dart';

/// Widget para los filtros de tareas (Todas, Pendientes, Completadas)
class FilterChipRow extends StatelessWidget {
  final bool? currentFilter;
  final Function(bool? filter) onFilterChanged;

  const FilterChipRow({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Todas',
              icon: Icons.list_rounded,
              isSelected: currentFilter == null,
              onTap: () => onFilterChanged(null),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'Pendientes',
              icon: Icons.radio_button_unchecked_rounded,
              isSelected: currentFilter == false,
              onTap: () => onFilterChanged(false),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'Completadas',
              icon: Icons.check_circle_rounded,
              isSelected: currentFilter == true,
              onTap: () => onFilterChanged(true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
