import 'package:flutter/material.dart';

import '../theme/cova_theme.dart';

class CovaPanel extends StatelessWidget {
  const CovaPanel({
    super.key,
    required this.child,
    this.padding,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: CovaColors.elevated.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Color.lerp(CovaColors.line, CovaColors.accent, glow ? 0.25 : 0)!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          if (glow)
            BoxShadow(
              color: CovaColors.accent.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  Color get _color {
    switch (status) {
      case 'DONE':
        return CovaColors.accent;
      case 'IN_PROGRESS':
        return CovaColors.info;
      default:
        return CovaColors.muted;
    }
  }

  String get _label {
    switch (status) {
      case 'DONE':
        return 'Termine';
      case 'IN_PROGRESS':
        return 'En cours';
      case 'TODO':
        return 'A faire';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final Map<String, String> options;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((entry) {
          final selected = entry.key == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onChanged(entry.key),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: selected ? CovaColors.accentInk : CovaColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              selectedColor: CovaColors.accent,
              backgroundColor: CovaColors.soft,
              side: BorderSide(
                color: selected ? CovaColors.accent : CovaColors.line,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }
}
