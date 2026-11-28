import 'package:material_ui/material_ui.dart';

import '../utils/time_utils.dart';

class DaySummaryRow extends StatelessWidget {
  const DaySummaryRow({super.key, required this.summary});

  final DaySummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;

    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(label, style: t.labelSmall),
          const SizedBox(height: 2),
          Text(value, style: t.titleSmall),
        ],
      ),
    );

    return Row(
      children: [
        stat('First in', formatTime(s.firstIn)),
        stat('Last out', s.lastOut == null ? 'still in' : formatTime(s.lastOut!)),
        stat('Span', s.span == null ? '-' : formatHm(s.span!)),
      ],
    );
  }
}
