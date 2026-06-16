import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/currency_formatter.dart';

class PieChartWidget extends StatefulWidget {
  final Map<String, double> categoryData;

  const PieChartWidget({super.key, required this.categoryData});

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.categoryData.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No expense data yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final total = widget.categoryData.values.fold(0.0, (a, b) => a + b);

    // Sort by value descending for better visual
    final sorted = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: _buildSections(sorted, total),
                  startDegreeOffset: -90,
                ),
              ),
              // Center label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.formatCompact(total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Legend as grid
        ...sorted.map((entry) {
          final percentage = (entry.value / total * 100);
          final idx = sorted.indexOf(entry);
          final isActive = idx == _touchedIndex;
          final color = AppColors.getCategoryColor(entry.key);
          return _LegendRow(
            color: color,
            icon: AppColors.getCategoryIcon(entry.key),
            label: entry.key,
            amount: CurrencyFormatter.formatCompact(entry.value),
            percentage: percentage,
            isActive: isActive,
            isDark: isDark,
          );
        }),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, double>> sorted,
    double total,
  ) {
    return List.generate(sorted.length, (i) {
      final isTouched = i == _touchedIndex;
      final entry = sorted[i];
      final percentage = entry.value / total * 100;
      final color = AppColors.getCategoryColor(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 60 : 48,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black38, blurRadius: 3)],
        ),
        titlePositionPercentageOffset: 0.55,
        borderSide: isTouched
            ? BorderSide(color: color.withValues(alpha: 0.8), width: 2)
            : BorderSide.none,
      );
    });
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String amount;
  final double percentage;
  final bool isActive;
  final bool isDark;

  const _LegendRow({
    required this.color,
    required this.icon,
    required this.label,
    required this.amount,
    required this.percentage,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: isDark ? 0.1 : 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
