import 'package:flutter/material.dart';

class MyActionItem {
  final String label;
  final VoidCallback onTap;

  MyActionItem({required this.label, required this.onTap});
}

class ActionChips extends StatefulWidget {
  final List<MyActionItem> chips;

  const ActionChips({super.key, required this.chips});

  @override
  State<ActionChips> createState() => _ActionChipsState();
}

class _ActionChipsState extends State<ActionChips> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chipCount = widget.chips.length;
          final spacing = 12.0;
          final totalSpacing = spacing * (chipCount - 1);
          final availableWidth = constraints.maxWidth - totalSpacing;
          final chipWidth = availableWidth / chipCount;

          return Row(
            children: widget.chips.asMap().entries.map((entry) {
              final index = entry.key;
              final chip = entry.value;
              final isSelected = index == _selectedIndex;

              return Padding(
                padding: EdgeInsets.only(
                  right: index < chipCount - 1 ? spacing : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    chip.onTap();
                  },
                  child: Container(
                    width: chipWidth,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7CB342)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      chip.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF558B2F),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
