import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = AppColors.getCategoryColor(expense.category);
    final catIcon = AppColors.getCategoryIcon(expense.category);

    // Auto-derive tags if none stored
    final displayTags = expense.tags.isNotEmpty
        ? expense.tags
        : [
            '#${expense.category.toLowerCase()}',
            if (expense.paymentMethod.isNotEmpty)
              '#${expense.paymentMethod.toLowerCase()}',
          ];

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.06 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category icon — gradient container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      catColor.withValues(alpha: 0.15),
                      catColor.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.merchantName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            expense.category,
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Payment method icon
                        Icon(
                          AppColors.getPaymentIcon(expense.paymentMethod),
                          size: 11,
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        const SizedBox(width: 3),
                        // Date
                        Flexible(
                          child: Text(
                            DateFormatter.formatDate(expense.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Tags
                    if (displayTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: displayTags.take(3).map((tag) {
                            return Text(
                              tag,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(expense.amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (expense.tax != null && expense.tax! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'tax ₹${expense.tax!.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 8,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onDismissed != null) {
      return Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.error.withValues(alpha: 0.02),
                theme.colorScheme.error.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Icon(
            Icons.delete_outline_rounded,
            color: theme.colorScheme.error,
            size: 24,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Expense'),
              content: Text(
                'Are you sure you want to delete "${expense.merchantName}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => onDismissed!(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: card,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: card,
    );
  }
}
