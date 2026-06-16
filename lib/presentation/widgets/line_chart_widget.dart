import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/color_constants.dart';

class LineChartWidget extends StatelessWidget {
  final Map<DateTime, double> data;
  final String title;
  final Color color;
  final bool showDots;
  final bool showLabels;

  const LineChartWidget({
    super.key,
    required this.data,
    this.title = '',
    this.color = AppColors.primaryLight,
    this.showDots = true,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (data.isEmpty) {
      return _EmptyState(theme: theme, text: 'No data for this period');
    }

    // Aggregate data intelligently based on range
    final sortedRaw = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totalDays = sortedRaw.length;

    final hasNonZero = sortedRaw.any((e) => e.value > 0);
    if (!hasNonZero) {
      return _EmptyState(theme: theme, text: 'No spending in this period');
    }

    // Decide aggregation: daily (<=14), weekly (15-60), monthly (>60)
    List<_ChartPoint> chartPoints;
    if (totalDays <= 14) {
      chartPoints = sortedRaw
          .map(
            (e) => _ChartPoint(
              date: e.key,
              value: e.value,
              label: DateFormat('EEE\nd').format(e.key),
            ),
          )
          .toList();
    } else if (totalDays <= 60) {
      chartPoints = _aggregateWeekly(sortedRaw);
    } else {
      chartPoints = _aggregateMonthly(sortedRaw);
    }

    if (chartPoints.isEmpty) {
      return _EmptyState(theme: theme, text: 'No data available');
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < chartPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), chartPoints[i].value));
    }

    final maxVal = chartPoints
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.2 : 100.0;
    final total = chartPoints.fold(0.0, (sum, e) => sum + e.value);
    final nonZeroDays = sortedRaw.where((e) => e.value > 0).length;
    final avgPerDay = nonZeroDays > 0
        ? sortedRaw.fold(0.0, (s, e) => s + e.value) / nonZeroDays
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              _StatChip(
                label: 'Total',
                value: '₹${_fmt(total)}',
                color: color,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: 'Avg/Day',
                value: '₹${_fmt(avgPerDay)}',
                color: AppColors.secondaryLight,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: 'Peak',
                value: '₹${_fmt(maxVal)}',
                color: AppColors.errorLight,
                isDark: isDark,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 3 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.dividerColor.withValues(alpha: 0.06),
                  strokeWidth: 1,
                  dashArray: [6, 4],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    interval: maxY > 0 ? maxY / 3 : 1,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == maxY) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '₹${_fmt(value)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: showLabels,
                    reservedSize: totalDays <= 14 ? 38 : 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= chartPoints.length) {
                        return const SizedBox.shrink();
                      }
                      // Smart interval: show max ~7 labels
                      final interval = (chartPoints.length / 7).ceil().clamp(
                        1,
                        99,
                      );
                      if (chartPoints.length > 7 &&
                          idx % interval != 0 &&
                          idx != chartPoints.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          chartPoints[idx].label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.4,
                            ),
                            height: 1.2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      String tooltipLabel = '';
                      if (idx >= 0 && idx < chartPoints.length) {
                        tooltipLabel = DateFormat(
                          'MMM d',
                        ).format(chartPoints[idx].date);
                      }
                      return LineTooltipItem(
                        '$tooltipLabel\n₹${spot.y.toStringAsFixed(0)}',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.22,
                  color: color,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: showDots && chartPoints.length <= 14,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3.5,
                        color: isDark ? AppColors.cardDark : Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: color,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        ),
      ],
    );
  }

  /// Aggregate daily data into weekly buckets
  List<_ChartPoint> _aggregateWeekly(List<MapEntry<DateTime, double>> data) {
    if (data.isEmpty) return [];
    final result = <_ChartPoint>[];
    DateTime weekStart = data.first.key;
    double weekTotal = 0;

    for (final entry in data) {
      if (entry.key.difference(weekStart).inDays >= 7) {
        result.add(
          _ChartPoint(
            date: weekStart,
            value: weekTotal,
            label: DateFormat('d MMM').format(weekStart),
          ),
        );
        weekStart = entry.key;
        weekTotal = 0;
      }
      weekTotal += entry.value;
    }
    // Last bucket
    result.add(
      _ChartPoint(
        date: weekStart,
        value: weekTotal,
        label: DateFormat('d MMM').format(weekStart),
      ),
    );
    return result;
  }

  /// Aggregate daily data into monthly buckets
  List<_ChartPoint> _aggregateMonthly(List<MapEntry<DateTime, double>> data) {
    if (data.isEmpty) return [];
    final monthMap = <String, _MonthBucket>{};
    for (final entry in data) {
      final key = '${entry.key.year}-${entry.key.month}';
      monthMap.putIfAbsent(
        key,
        () => _MonthBucket(DateTime(entry.key.year, entry.key.month), 0),
      );
      monthMap[key]!.total += entry.value;
    }
    return monthMap.values
        .map(
          (b) => _ChartPoint(
            date: b.month,
            value: b.total,
            label: DateFormat('MMM').format(b.month),
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  String _fmt(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}

class _ChartPoint {
  final DateTime date;
  final double value;
  final String label;
  _ChartPoint({required this.date, required this.value, required this.label});
}

class _MonthBucket {
  final DateTime month;
  double total;
  _MonthBucket(this.month, this.total);
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  final String text;
  const _EmptyState({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 32,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
