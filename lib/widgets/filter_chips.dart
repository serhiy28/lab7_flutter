import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onStatusChanged;

  const FilterChips({
    Key? key,
    required this.selectedStatus,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(
            label: 'Всі',
            value: 'all',
            icon: Icons.grid_view,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Переглянуто',
            value: 'watched',
            icon: Icons.check_circle,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Заплановано',
            value: 'planned',
            icon: Icons.bookmark,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = selectedStatus == value;

    return Expanded(
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onStatusChanged(value),
        backgroundColor: const Color(0xFF1a1a2e),
        selectedColor: const Color(0xFF7C3AED),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
