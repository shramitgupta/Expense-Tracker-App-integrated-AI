import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/color_constants.dart';
import '../../data/models/expense_model.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_state.dart';
import '../blocs/insights/insights_bloc.dart';
import '../blocs/insights/insights_event.dart';
import '../blocs/insights/insights_state.dart';
import '../widgets/markdown_text.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Insights')),
      body: BlocBuilder<InsightsBloc, InsightsState>(
        builder: (context, insightsState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E2A3A), const Color(0xFF162030)]
                          : [const Color(0xFFEDF5FF), const Color(0xFFE0ECFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.secondaryGradient[0].withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.secondaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryGradient[0].withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Spending Insights',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'AI analyzes your spending patterns\nand gives personalized tips.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.55,
                          ),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: insightsState is InsightsLoading
                              ? null
                              : () => _generateInsights(context),
                          icon: insightsState is InsightsLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            insightsState is InsightsLoading
                                ? 'Analyzing...'
                                : 'Generate Insights',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Results
                if (insightsState is InsightsLoading) _buildLoadingState(theme),

                if (insightsState is InsightsGenerated)
                  _buildInsightsReport(theme, isDark, insightsState.report),

                if (insightsState is InsightsFailure)
                  _buildErrorState(theme, insightsState.message, context),

                if (insightsState is InsightsInitial) _buildInitialState(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  void _generateInsights(BuildContext context) {
    final expenseState = context.read<ExpenseBloc>().state;
    if (expenseState is ExpenseLoaded) {
      if (expenseState.expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add some expenses first to generate insights.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final expenseData = expenseState.expenses.map((e) {
        return ExpenseModel.fromEntity(e).toJson();
      }).toList();

      context.read<InsightsBloc>().add(GenerateInsightsEvent(expenseData));
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Generating insights...',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI is analyzing your spending patterns',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsReport(ThemeData theme, bool isDark, String report) {
    // Parse the report into sections
    final sections = _parseReport(report);

    return Column(
      children: [
        // Report header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: isDark ? 0.08 : 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Analysis complete! Here are your insights.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Render sections
        ...sections.map(
          (section) => _InsightSectionCard(
            title: section.title,
            content: section.content,
            theme: theme,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  List<_InsightSection> _parseReport(String report) {
    final lines = report.split('\n');
    final sections = <_InsightSection>[];
    String currentTitle = 'Summary';
    final currentContent = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      // Detect section headers: lines starting with ** or ##
      if ((trimmed.startsWith('**') && trimmed.endsWith('**')) ||
          trimmed.startsWith('## ') ||
          trimmed.startsWith('# ')) {
        if (currentContent.isNotEmpty) {
          sections.add(
            _InsightSection(
              title: currentTitle,
              content: currentContent.toString().trim(),
            ),
          );
          currentContent.clear();
        }
        currentTitle = trimmed
            .replaceAll('**', '')
            .replaceAll('## ', '')
            .replaceAll('# ', '')
            .trim();
      } else if (trimmed.isNotEmpty) {
        currentContent.writeln(trimmed);
      }
    }

    if (currentContent.isNotEmpty) {
      sections.add(
        _InsightSection(
          title: currentTitle,
          content: currentContent.toString().trim(),
        ),
      );
    }

    // If no sections were found, return the whole report as one section
    if (sections.isEmpty) {
      sections.add(
        _InsightSection(title: 'AI Analysis', content: report.trim()),
      );
    }

    return sections;
  }

  Widget _buildErrorState(
    ThemeData theme,
    String message,
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            'Failed to Generate',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _generateInsights(context),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 44,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap "Generate Insights" to get started',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSection {
  final String title;
  final String content;

  _InsightSection({required this.title, required this.content});
}

class _InsightSectionCard extends StatelessWidget {
  final String title;
  final String content;
  final ThemeData theme;
  final bool isDark;

  const _InsightSectionCard({
    required this.title,
    required this.content,
    required this.theme,
    required this.isDark,
  });

  IconData _getIconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('summary') || lower.contains('overview')) {
      return Icons.summarize_rounded;
    } else if (lower.contains('category') || lower.contains('breakdown')) {
      return Icons.pie_chart_rounded;
    } else if (lower.contains('trend') || lower.contains('pattern')) {
      return Icons.trending_up_rounded;
    } else if (lower.contains('recommend') ||
        lower.contains('tip') ||
        lower.contains('suggestion')) {
      return Icons.lightbulb_rounded;
    } else if (lower.contains('top') ||
        lower.contains('highest') ||
        lower.contains('largest')) {
      return Icons.arrow_upward_rounded;
    } else if (lower.contains('saving') || lower.contains('budget')) {
      return Icons.savings_rounded;
    } else if (lower.contains('alert') || lower.contains('warning')) {
      return Icons.warning_rounded;
    }
    return Icons.insights_rounded;
  }

  Color _getColorForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('summary') || lower.contains('overview')) {
      return AppColors.primaryLight;
    } else if (lower.contains('category') || lower.contains('breakdown')) {
      return AppColors.travelColor;
    } else if (lower.contains('trend') || lower.contains('pattern')) {
      return AppColors.secondaryLight;
    } else if (lower.contains('recommend') ||
        lower.contains('tip') ||
        lower.contains('suggestion')) {
      return AppColors.shoppingColor;
    } else if (lower.contains('top') ||
        lower.contains('highest') ||
        lower.contains('largest')) {
      return AppColors.foodColor;
    } else if (lower.contains('saving') || lower.contains('budget')) {
      return Colors.green;
    }
    return AppColors.entertainmentColor;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForTitle(title);
    final color = _getColorForTitle(title);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MarkdownText(
            text: content,
            baseStyle: theme.textTheme.bodySmall?.copyWith(
              height: 1.6,
              fontSize: 12.5,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
