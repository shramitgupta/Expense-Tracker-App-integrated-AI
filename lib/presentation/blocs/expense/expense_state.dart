import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense.dart';
import 'expense_event.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;
  final List<Expense> filteredExpenses;
  final String searchQuery;
  final SortOption sortOption;

  const ExpenseLoaded({
    required this.expenses,
    required this.filteredExpenses,
    this.searchQuery = '',
    this.sortOption = SortOption.dateDesc,
  });

  double get totalExpenses =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get thisMonthExpenses {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get lastMonthExpenses {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return expenses
        .where((e) =>
            e.date.year == lastMonth.year && e.date.month == lastMonth.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (final expense in expenses) {
      map[expense.category] = (map[expense.category] ?? 0.0) + expense.amount;
    }
    return map;
  }

  List<Expense> get recentExpenses {
    final sorted = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  /// Daily spending for the last 7 days
  Map<DateTime, double> get weeklySpendingTrend {
    final now = DateTime.now();
    final result = <DateTime, double>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
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

  /// Monthly totals for the last 6 months
  Map<DateTime, double> get monthlyTrend {
    final now = DateTime.now();
    final result = <DateTime, double>{};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final total = expenses
          .where((e) =>
              e.date.year == month.year && e.date.month == month.month)
          .fold(0.0, (sum, e) => sum + e.amount);
      result[month] = total;
    }
    return result;
  }

  /// Detect recurring expenses (same merchant, appears 2+ months)
  List<RecurringExpense> get recurringExpenses {
    final merchantMonths = <String, Set<String>>{};
    final merchantAmounts = <String, List<double>>{};

    for (final e in expenses) {
      final key = e.merchantName.toLowerCase().trim();
      if (key.isEmpty) continue;
      final monthKey = '${e.date.year}-${e.date.month}';
      merchantMonths.putIfAbsent(key, () => {}).add(monthKey);
      merchantAmounts.putIfAbsent(key, () => []).add(e.amount);
    }

    final result = <RecurringExpense>[];
    for (final entry in merchantMonths.entries) {
      if (entry.value.length >= 2) {
        final amounts = merchantAmounts[entry.key]!;
        final avgAmount = amounts.fold(0.0, (s, a) => s + a) / amounts.length;
        // Find original case name
        final originalName = expenses
            .firstWhere(
                (e) => e.merchantName.toLowerCase().trim() == entry.key)
            .merchantName;
        result.add(RecurringExpense(
          merchantName: originalName,
          monthlyAvg: avgAmount,
          occurrences: entry.value.length,
        ));
      }
    }
    result.sort((a, b) => b.monthlyAvg.compareTo(a.monthlyAvg));
    return result;
  }

  /// Top spending categories sorted by amount
  List<MapEntry<String, double>> get topCategories {
    final entries = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Group expenses by date for timeline view
  Map<String, List<Expense>> get groupedByDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final sorted = List<Expense>.from(filteredExpenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    final groups = <String, List<Expense>>{};
    for (final expense in sorted) {
      final expDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      String key;
      if (expDate == today) {
        key = 'Today';
      } else if (expDate == yesterday) {
        key = 'Yesterday';
      } else if (expDate.isAfter(weekAgo)) {
        key = 'This Week';
      } else if (expDate.month == now.month && expDate.year == now.year) {
        key = 'This Month';
      } else {
        key = 'Older';
      }
      groups.putIfAbsent(key, () => []).add(expense);
    }
    return groups;
  }

  ExpenseLoaded copyWith({
    List<Expense>? expenses,
    List<Expense>? filteredExpenses,
    String? searchQuery,
    SortOption? sortOption,
  }) {
    return ExpenseLoaded(
      expenses: expenses ?? this.expenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  List<Object?> get props => [expenses, filteredExpenses, searchQuery, sortOption];
}

class RecurringExpense {
  final String merchantName;
  final double monthlyAvg;
  final int occurrences;

  const RecurringExpense({
    required this.merchantName,
    required this.monthlyAvg,
    required this.occurrences,
  });
}

class ExpenseError extends ExpenseState {
  final String message;
  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
