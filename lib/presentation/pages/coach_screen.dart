import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/color_constants.dart';
import '../../data/models/expense_model.dart';
import '../blocs/coach/coach_bloc.dart';
import '../blocs/coach/coach_event.dart';
import '../blocs/coach/coach_state.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_state.dart';
import '../widgets/health_score_gauge.dart';
import '../widgets/markdown_text.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  int _selectedTab = 0; // 0=Coach, 1=Health Score

  List<Map<String, dynamic>> _getExpenseData() {
    final state = context.read<ExpenseBloc>().state;
    if (state is ExpenseLoaded && state.expenses.isNotEmpty) {
      return state.expenses.map((e) => ExpenseModel.fromEntity(e).toJson()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          children: [
            // ─── Header ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [theme.colorScheme.surface, theme.colorScheme.surface.withValues(alpha: 0.7)]
                      : [
                          theme.colorScheme.primary.withValues(alpha: 0.06),
                          theme.colorScheme.primary.withValues(alpha: 0.02),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.coachGradient[0].withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.coachGradient,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coachGradient[0].withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your AI Financial Coach',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get personalized spending advice,\nhealth score & budget plans.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ─── Tab Selector ───
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _TabButton(
                    label: '🧠  Coach',
                    isActive: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  _TabButton(
                    label: '💚  Health Score',
                    isActive: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ─── Action Buttons ───
            if (_selectedTab == 0) ...[
              _buildCoachSection(theme, isDark),
            ] else ...[
              _buildHealthScoreSection(theme, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoachSection(ThemeData theme, bool isDark) {
    return BlocBuilder<CoachBloc, CoachState>(
      builder: (context, state) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: state is CoachLoading
                    ? null
                    : () {
                        final data = _getExpenseData();
                        if (data.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add expenses first.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        context
                            .read<CoachBloc>()
                            .add(GenerateCoachAdvice(data));
                      },
                icon: state is CoachLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.psychology_rounded, size: 18),
                label: Text(
                  state is CoachLoading
                      ? 'Analyzing...'
                      : 'Analyze My Spending',
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            if (state is CoachLoading)
              _buildLoadingCard(theme, state.message),

            if (state is CoachAdviceGenerated)
              _buildCoachReport(theme, isDark, state.advice),

            if (state is CoachError)
              _buildErrorCard(theme, state.message),

            if (state is CoachInitial)
              _buildPlaceholder(
                theme,
                icon: Icons.psychology_outlined,
                text: 'Tap "Analyze My Spending" for AI coaching',
              ),
          ],
        );
      },
    );
  }

  Widget _buildHealthScoreSection(ThemeData theme, bool isDark) {
    return BlocBuilder<CoachBloc, CoachState>(
      builder: (context, state) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: state is CoachLoading
                    ? null
                    : () {
                        final data = _getExpenseData();
                        if (data.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add expenses first.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        context
                            .read<CoachBloc>()
                            .add(GenerateHealthScore(data));
                      },
                icon: state is CoachLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.favorite_rounded, size: 18),
                label: Text(
                  state is CoachLoading
                      ? 'Calculating...'
                      : 'Calculate Health Score',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryGradient[0],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            if (state is CoachLoading)
              _buildLoadingCard(theme, state.message),

            if (state is HealthScoreGenerated)
              _buildHealthScoreResult(theme, isDark, state),

            if (state is CoachError)
              _buildErrorCard(theme, state.message),

            if (state is CoachInitial)
              _buildPlaceholder(
                theme,
                icon: Icons.favorite_outline_rounded,
                text: 'Tap "Calculate Health Score" to see your financial health',
              ),
          ],
        );
      },
    );
  }

  Widget _buildCoachReport(ThemeData theme, bool isDark, String report) {
    final sections = _parseReport(report);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: isDark ? 0.08 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Coaching report ready!',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...sections.map((s) => _CoachSectionCard(
              title: s.title,
              content: s.content,
              theme: theme,
              isDark: isDark,
            )),
      ],
    );
  }

  Widget _buildHealthScoreResult(
    ThemeData theme,
    bool isDark,
    HealthScoreGenerated state,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Financial Health',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              HealthScoreGauge(
                score: state.score,
                label: state.label,
              ),
              const SizedBox(height: 12),
              if (state.summary.isNotEmpty)
                Text(
                  state.summary,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Breakdown
        if (state.breakdown.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score Breakdown',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ...state.breakdown.entries.map((e) {
                  final label = e.key
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((w) =>
                          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                      .join(' ');
                  return _BreakdownRow(
                    label: label,
                    score: e.value,
                    theme: theme,
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingCard(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, {required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 10),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  List<_Section> _parseReport(String report) {
    final lines = report.split('\n');
    final sections = <_Section>[];
    String currentTitle = 'Summary';
    final currentContent = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if ((trimmed.startsWith('**') && trimmed.endsWith('**')) ||
          trimmed.startsWith('## ') ||
          trimmed.startsWith('# ')) {
        if (currentContent.isNotEmpty) {
          sections.add(_Section(currentTitle, currentContent.toString().trim()));
          currentContent.clear();
        }
        currentTitle = trimmed.replaceAll('**', '').replaceAll('## ', '').replaceAll('# ', '').trim();
      } else if (trimmed.isNotEmpty) {
        currentContent.writeln(trimmed);
      }
    }
    if (currentContent.isNotEmpty) {
      sections.add(_Section(currentTitle, currentContent.toString().trim()));
    }
    if (sections.isEmpty) {
      sections.add(_Section('AI Coach', report.trim()));
    }
    return sections;
  }
}

class _Section {
  final String title;
  final String content;
  _Section(this.title, this.content);
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachSectionCard extends StatelessWidget {
  final String title;
  final String content;
  final ThemeData theme;
  final bool isDark;

  const _CoachSectionCard({
    required this.title,
    required this.content,
    required this.theme,
    required this.isDark,
  });

  IconData _getIcon() {
    final l = title.toLowerCase();
    if (l.contains('strength')) return Icons.thumb_up_rounded;
    if (l.contains('concern') || l.contains('weak')) return Icons.warning_rounded;
    if (l.contains('saving') || l.contains('opportunit')) return Icons.savings_rounded;
    if (l.contains('budget')) return Icons.account_balance_wallet_rounded;
    if (l.contains('challenge')) return Icons.flag_rounded;
    return Icons.lightbulb_rounded;
  }

  Color _getColor() {
    final l = title.toLowerCase();
    if (l.contains('strength')) return Colors.green;
    if (l.contains('concern') || l.contains('weak')) return AppColors.foodColor;
    if (l.contains('saving') || l.contains('opportunit')) return AppColors.secondaryLight;
    if (l.contains('budget')) return AppColors.primaryLight;
    if (l.contains('challenge')) return AppColors.entertainmentColor;
    return AppColors.shoppingColor;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final color = _getColor();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
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
          const SizedBox(height: 8),
          MarkdownText(
            text: content,
            baseStyle: theme.textTheme.bodySmall?.copyWith(
              height: 1.6,
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int score;
  final ThemeData theme;

  const _BreakdownRow({
    required this.label,
    required this.score,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getHealthColor(score.toDouble());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$score/100',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
              color: color,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
