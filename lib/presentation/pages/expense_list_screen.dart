import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/color_constants.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_event.dart';
import '../blocs/expense/expense_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/empty_state_widget.dart';
import 'add_edit_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _searchController = TextEditingController();
  SortOption _currentSort = SortOption.dateDesc;
  String? _selectedCategory;

  final _categories = [
    'Food',
    'Shopping',
    'Travel',
    'Utilities',
    'Entertainment',
    'Health',
    'Education',
    'Subscription',
    'Others',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort expenses',
            onSelected: (option) {
              setState(() => _currentSort = option);
              context.read<ExpenseBloc>().add(SortExpenses(option));
            },
            itemBuilder: (_) => [
              _buildSortItem(
                SortOption.dateDesc,
                'Newest',
                Icons.arrow_downward_rounded,
              ),
              _buildSortItem(
                SortOption.dateAsc,
                'Oldest',
                Icons.arrow_upward_rounded,
              ),
              _buildSortItem(
                SortOption.amountDesc,
                'Highest',
                Icons.arrow_downward_rounded,
              ),
              _buildSortItem(
                SortOption.amountAsc,
                'Lowest',
                Icons.arrow_upward_rounded,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_list_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by merchant, notes...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ExpenseBloc>().add(
                            const SearchExpenses(''),
                          );
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<ExpenseBloc>().add(SearchExpenses(value));
                setState(() {});
              },
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    context.read<ExpenseBloc>().add(const SearchExpenses(''));
                  },
                  color: theme.colorScheme.primary,
                ),
                ..._categories.map(
                  (cat) => _FilterChip(
                    label: cat,
                    isSelected: _selectedCategory == cat,
                    onTap: () {
                      setState(() {
                        _selectedCategory = _selectedCategory == cat
                            ? null
                            : cat;
                      });
                    },
                    color: AppColors.getCategoryColor(cat),
                    icon: AppColors.getCategoryIcon(cat),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Timeline Expense List
          Expanded(
            child: BlocBuilder<ExpenseBloc, ExpenseState>(
              builder: (context, state) {
                if (state is ExpenseLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ExpenseError) {
                  return Center(child: Text(state.message));
                }

                if (state is ExpenseLoaded) {
                  // Apply category filter
                  final grouped = state.groupedByDate;
                  final filteredGroups = <String, List<dynamic>>{};
                  for (final entry in grouped.entries) {
                    final filtered = _selectedCategory != null
                        ? entry.value
                              .where((e) => e.category == _selectedCategory)
                              .toList()
                        : entry.value;
                    if (filtered.isNotEmpty) {
                      filteredGroups[entry.key] = filtered;
                    }
                  }

                  if (filteredGroups.isEmpty) {
                    if (state.searchQuery.isNotEmpty ||
                        _selectedCategory != null) {
                      return EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No results found',
                        subtitle: 'Try a different filter',
                      );
                    }
                    return const EmptyStateWidget(
                      icon: Icons.receipt_long_rounded,
                      title: 'No expenses yet',
                      subtitle: 'Start adding expenses to see them here.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredGroups.entries.fold(0, (sum, e) {
                      return sum! + 1 + e.value.length; // header + items
                    }),
                    itemBuilder: (context, index) {
                      int current = 0;
                      for (final entry in filteredGroups.entries) {
                        if (index == current) {
                          return _TimelineHeader(
                            label: entry.key,
                            count: entry.value.length,
                            theme: theme,
                          );
                        }
                        current++;
                        if (index < current + entry.value.length) {
                          final expense = entry.value[index - current];
                          return ExpenseCard(
                            expense: expense,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditExpenseScreen(expense: expense),
                              ),
                            ),
                            onDismissed: () {
                              context.read<ExpenseBloc>().add(
                                DeleteExpenseEvent(expense.id),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${expense.merchantName} deleted',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        }
                        current += entry.value.length;
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortOption> _buildSortItem(
    SortOption option,
    String label,
    IconData icon,
  ) {
    final isSelected = _currentSort == option;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : theme.dividerColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? color
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  final String label;
  final int count;
  final ThemeData theme;

  const _TimelineHeader({
    required this.label,
    required this.count,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}
