import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/expense.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_event.dart';
import '../blocs/expense/expense_state.dart';
import '../blocs/theme/theme_cubit.dart';
import '../widgets/summary_card.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/line_chart_widget.dart';
import '../widgets/expense_card.dart';
import '../widgets/empty_state_widget.dart';
import 'add_edit_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(const LoadExpenses());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGradient[0]
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ExpenseIQ',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'AI Financial Assistant',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: BlocBuilder<ThemeCubit, bool>(
                    builder: (context, isDark) {
                      return Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 19,
                      );
                    },
                  ),
                  onPressed: () =>
                      context.read<ThemeCubit>().toggleTheme(),
                ),
              ),
              const SizedBox(width: 2),
            ],
          ),

          // Body
          SliverToBoxAdapter(
            child: BlocBuilder<ExpenseBloc, ExpenseState>(
              builder: (context, state) {
                if (state is ExpenseLoading) {
                  return const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is ExpenseError) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context
                                .read<ExpenseBloc>()
                                .add(const LoadExpenses()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is ExpenseLoaded) {
                  if (state.expenses.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'No expenses yet',
                      subtitle:
                          'Tap the + button to add your first expense\nor scan a receipt to get started.',
                      action: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEditExpenseScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Expense'),
                      ),
                    );
                  }

                  return _DashboardBody(state: state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  final ExpenseLoaded state;

  const _DashboardBody({required this.state});

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  int _selectedRange = 0; // 0=7D, 1=14D, 2=1M, 3=3M, 4=Custom
  DateTimeRange? _customRange;

  static const _rangeLabels = ['7 Days', '14 Days', '1 Month', '3 Months', 'Custom'];
  static const _rangeDays = [7, 14, 30, 90, 0];

  DateTime get _rangeStart {
    if (_selectedRange == 4 && _customRange != null) {
      return _customRange!.start;
    }
    return DateTime.now().subtract(Duration(days: _rangeDays[_selectedRange]));
  }

  DateTime get _rangeEnd {
    if (_selectedRange == 4 && _customRange != null) {
      return _customRange!.end;
    }
    return DateTime.now();
  }

  List<Expense> get _rangedExpenses {
    final start = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    return widget.state.expenses.where((e) {
      final expDate = DateTime(e.date.year, e.date.month, e.date.day);
      return !expDate.isBefore(start) && !expDate.isAfter(_rangeEnd);
    }).toList();
  }

  Map<DateTime, double> get _rangedDailySpending {
    final expenses = _rangedExpenses;
    final start = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    final end = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day);
    final days = end.difference(start).inDays + 1;

    final result = <DateTime, double>{};
    for (int i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      final total = expenses
          .where((e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold(0.0, (sum, e) => sum + e.amount);
      result[day] = total;
    }
    return result;
  }

  Map<String, double> get _rangedCategoryBreakdown {
    final map = <String, double>{};
    for (final e in _rangedExpenses) {
      map[e.category] = (map[e.category] ?? 0.0) + e.amount;
    }
    return map;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedRange = 4;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final todayTotal = widget.state.expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);

    final weekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final thisWeekTotal = widget.state.expenses
        .where((e) => e.date.isAfter(
            DateTime(weekStart.year, weekStart.month, weekStart.day)
                .subtract(const Duration(days: 1))))
        .fold(0.0, (sum, e) => sum + e.amount);

    final uniqueDays = widget.state.expenses
        .map((e) => '${e.date.year}-${e.date.month}-${e.date.day}')
        .toSet()
        .length
        .clamp(1, 999);
    final avgPerDay = widget.state.totalExpenses / uniqueDays;

    final highestExpense = (List<Expense>.from(widget.state.expenses)
          ..sort((a, b) => b.amount.compareTo(a.amount)))
        .first;

    // Prediction: simple linear extrapolation
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final predictedMonthly = daysPassed > 0
        ? (widget.state.thisMonthExpenses / daysPassed) * daysInMonth
        : widget.state.thisMonthExpenses;

    // Ranged data for charts
    final rangedDaily = _rangedDailySpending;
    final rangedCategories = _rangedCategoryBreakdown;
    final rangedExpenses = _rangedExpenses;
    final rangedTotal = rangedExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),

        // ─── Summary Cards ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Total Spent',
                    value: CurrencyFormatter.formatCompact(
                        widget.state.totalExpenses),
                    icon: Icons.account_balance_wallet_rounded,
                    gradientColors: AppColors.primaryGradient,
                    subtitle: '${widget.state.expenses.length} transactions',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SummaryCard(
                    title: 'This Month',
                    value: CurrencyFormatter.formatCompact(
                        widget.state.thisMonthExpenses),
                    icon: Icons.calendar_today_rounded,
                    gradientColors: AppColors.secondaryGradient,
                    subtitle: DateFormat('MMM yyyy').format(now),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ─── Quick Stats ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _QuickStat(
                icon: Icons.today_rounded,
                label: 'Today',
                value: CurrencyFormatter.formatCompact(todayTotal),
                color: AppColors.foodColor,
              ),
              const SizedBox(width: 8),
              _QuickStat(
                icon: Icons.date_range_rounded,
                label: 'Week',
                value: CurrencyFormatter.formatCompact(thisWeekTotal),
                color: AppColors.travelColor,
              ),
              const SizedBox(width: 8),
              _QuickStat(
                icon: Icons.trending_up_rounded,
                label: 'Avg/Day',
                value: CurrencyFormatter.formatCompact(avgPerDay),
                color: AppColors.entertainmentColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Spending Prediction ───
        _SectionCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.auto_graph_rounded,
          iconColor: AppColors.secondaryLight,
          title: 'Monthly Prediction',
          child: Row(
            children: [
              Expanded(
                child: _PredictionBlock(
                  label: 'Current',
                  value: CurrencyFormatter.formatCompact(
                      widget.state.thisMonthExpenses),
                  theme: theme,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.3),
                ),
              ),
              Expanded(
                child: _PredictionBlock(
                  label: 'Predicted',
                  value: CurrencyFormatter.formatCompact(predictedMonthly),
                  theme: theme,
                  isHighlighted: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ─── Highest Expense ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.accentGradient[0].withValues(alpha: 0.07)
                  : AppColors.accentGradient[0].withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color:
                      AppColors.accentGradient[0].withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        AppColors.accentGradient[0].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_upward_rounded,
                      size: 14, color: AppColors.accentGradient[0]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Highest Expense',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.45))),
                      Text(highestExpense.merchantName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(CurrencyFormatter.format(highestExpense.amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentGradient[0])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ═══════════════════════════════════════════
        // ─── DATE RANGE SELECTOR ───
        // ═══════════════════════════════════════════
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 15,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Spending Analysis',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // Range total badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${CurrencyFormatter.formatCompact(rangedTotal)} · ${rangedExpenses.length} txns',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Range chips
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _rangeLabels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final isActive = _selectedRange == i;
                    return GestureDetector(
                      onTap: () {
                        if (i == 4) {
                          _pickCustomRange();
                        } else {
                          setState(() => _selectedRange = i);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (i == 4) ...[
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 12,
                                color: isActive ? Colors.white : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              i == 4 && _customRange != null && isActive
                                  ? '${DateFormat('d MMM').format(_customRange!.start)} - ${DateFormat('d MMM').format(_customRange!.end)}'
                                  : _rangeLabels[i],
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ─── Spending Trend (ranged) ───
        _SectionCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.show_chart_rounded,
          iconColor: AppColors.primaryLight,
          title: 'Spending Trend',
          child: LineChartWidget(
            data: rangedDaily,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: 14),

        // ─── Category Chart (ranged) ───
        _SectionCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.pie_chart_rounded,
          iconColor: theme.colorScheme.primary,
          title: 'Category Breakdown',
          child: PieChartWidget(categoryData: rangedCategories),
        ),
        const SizedBox(height: 14),

        // ─── Monthly Comparison ───
        _SectionCard(
          theme: theme,
          isDark: isDark,
          icon: Icons.compare_arrows_rounded,
          iconColor: AppColors.secondaryLight,
          title: 'Monthly Comparison',
          child: _MonthlyComparison(state: widget.state, theme: theme),
        ),
        const SizedBox(height: 14),

        // ─── Recurring Expenses ───
        if (widget.state.recurringExpenses.isNotEmpty) ...[
          _SectionCard(
            theme: theme,
            isDark: isDark,
            icon: Icons.replay_rounded,
            iconColor: AppColors.subscriptionColor,
            title: 'Recurring Expenses',
            child: Column(
              children: widget.state.recurringExpenses
                  .take(5)
                  .map((r) => _RecurringRow(
                        name: r.merchantName,
                        monthly: r.monthlyAvg,
                        count: r.occurrences,
                        theme: theme,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ─── Recent Transactions ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.state.recentExpenses.length} of ${widget.state.expenses.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...widget.state.recentExpenses.map(
          (expense) => ExpenseCard(
            expense: expense,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddEditExpenseScreen(expense: expense),
              ),
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ─── Reusable Section Card ───
class _SectionCard extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.theme,
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.08 : 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.08 : 0.02),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withValues(alpha: 0.12),
                        iconColor.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 15, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Quick Stat ───
class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.08 : 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.06 : 0.015),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Prediction Block ───
class _PredictionBlock extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isHighlighted;

  const _PredictionBlock({
    required this.label,
    required this.value,
    required this.theme,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.dividerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.45))),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: isHighlighted ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Monthly Comparison ───
class _MonthlyComparison extends StatelessWidget {
  final ExpenseLoaded state;
  final ThemeData theme;

  const _MonthlyComparison({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final diff = state.thisMonthExpenses - state.lastMonthExpenses;
    final isUp = diff > 0;
    final pct = state.lastMonthExpenses > 0
        ? ((diff / state.lastMonthExpenses) * 100).abs()
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _PredictionBlock(
            label: DateFormat('MMM').format(lastMonthDate),
            value: CurrencyFormatter.formatCompact(
                state.lastMonthExpenses),
            theme: theme,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Icon(
                isUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: isUp ? AppColors.errorLight : Colors.green,
                size: 18,
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: isUp ? AppColors.errorLight : Colors.green,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _PredictionBlock(
            label: DateFormat('MMM').format(now),
            value: CurrencyFormatter.formatCompact(
                state.thisMonthExpenses),
            theme: theme,
            isHighlighted: true,
          ),
        ),
      ],
    );
  }
}

// ─── Recurring Row ───
class _RecurringRow extends StatelessWidget {
  final String name;
  final double monthly;
  final int count;
  final ThemeData theme;

  const _RecurringRow({
    required this.name,
    required this.monthly,
    required this.count,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.subscriptionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.replay_rounded,
                size: 12, color: AppColors.subscriptionColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                Text('$count months detected',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('~₹${monthly.toStringAsFixed(0)}/mo',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700, fontSize: 12)),
              Text('~₹${(monthly * 12).toStringAsFixed(0)}/yr',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.4))),
            ],
          ),
        ],
      ),
    );
  }
}
