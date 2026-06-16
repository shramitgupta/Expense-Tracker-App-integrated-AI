import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/color_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../blocs/receipt/receipt_bloc.dart';
import '../blocs/receipt/receipt_event.dart';
import '../blocs/receipt/receipt_state.dart';
import 'add_edit_expense_screen.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  final _picker = ImagePicker();
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _selectedImage = File(image.path));
        context.read<ReceiptBloc>().add(ScanReceipt(File(image.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToAddExpense(ReceiptSuccess state) {
    final data = state.receiptData;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditExpenseScreen(
          prefillMerchant: data.merchantName,
          prefillAmount: data.amount,
          prefillDate: data.date,
          prefillCategory: data.category,
          prefillPaymentMethod: data.paymentMethod,
          prefillTax: data.tax,
          prefillConfidence: data.confidenceScore,
        ),
      ),
    ).then((_) {
      if (mounted) {
        context.read<ReceiptBloc>().add(const ResetReceipt());
        setState(() => _selectedImage = null);
      }
    });
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: BlocBuilder<ReceiptBloc, ReceiptState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              children: [
                // ─── Header Card ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF2A2A4A),
                              const Color(0xFF1E1E3A),
                            ]
                          : [
                              const Color(0xFFF0EDFF),
                              const Color(0xFFE8E4FF),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGradient[0]
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI Receipt Scanner',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Capture or select a receipt image.\nAI extracts merchant, amount, date & category.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.6),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Capture Buttons ───
                Row(
                  children: [
                    Expanded(
                      child: _CaptureButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        subtitle: 'Take photo',
                        gradient: AppColors.primaryGradient,
                        disabled: state is ReceiptLoading,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CaptureButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        subtitle: 'Choose image',
                        gradient: AppColors.secondaryGradient,
                        disabled: state is ReceiptLoading,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Image Preview ───
                if (_selectedImage != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          Image.file(
                            _selectedImage!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          // Overlay gradient
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.4),
                                  ],
                                ),
                              ),
                              alignment: Alignment.bottomCenter,
                              padding: const EdgeInsets.only(bottom: 10),
                              child: const Text(
                                'Receipt Image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // Loading overlay
                          if (state is ReceiptLoading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Center(
                                  child: RotationTransition(
                                    turns: _loadingController,
                                    child: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                if (_selectedImage != null) const SizedBox(height: 20),

                // ─── Loading State ───
                if (state is ReceiptLoading)
                  _buildLoadingCard(theme),

                // ─── Success State — Show Extracted Data ───
                if (state is ReceiptSuccess)
                  _buildSuccessCard(theme, state),

                // ─── Error State ───
                if (state is ReceiptFailure)
                  _buildErrorCard(theme, state.message),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Analyzing receipt...',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI is extracting merchant, amount, date and category',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(ThemeData theme, ReceiptSuccess state) {
    final data = state.receiptData;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Confidence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Extraction Successful',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ),
              if (data.confidenceScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(data.confidenceScore).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getConfidenceColor(data.confidenceScore).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'AI: ${(data.confidenceScore * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: _getConfidenceColor(data.confidenceScore),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
          const SizedBox(height: 12),

          // Extracted fields
          _ExtractedField(
            icon: Icons.store_rounded,
            label: 'Merchant',
            value: data.merchantName.isNotEmpty ? data.merchantName : 'Not detected',
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 12),
          _ExtractedField(
            icon: Icons.currency_rupee_rounded,
            label: 'Amount',
            value: data.amount > 0
                ? CurrencyFormatter.format(data.amount)
                : 'Not detected',
            color: AppColors.secondaryLight,
          ),
          const SizedBox(height: 12),
          _ExtractedField(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: data.date != null
                ? DateFormatter.formatDate(data.date!)
                : 'Not detected',
            color: AppColors.foodColor,
          ),
          const SizedBox(height: 12),
          _ExtractedField(
            icon: AppColors.getCategoryIcon(data.category),
            label: 'Category',
            value: data.category,
            color: AppColors.getCategoryColor(data.category),
          ),
          if (data.tax != null && data.tax! > 0) ...[   
            const SizedBox(height: 12),
            _ExtractedField(
              icon: Icons.receipt_outlined,
              label: 'Tax',
              value: CurrencyFormatter.format(data.tax!),
              color: AppColors.utilitiesColor,
            ),
          ],
          const SizedBox(height: 12),
          _ExtractedField(
            icon: AppColors.getPaymentIcon(data.paymentMethod),
            label: 'Payment',
            value: data.paymentMethod,
            color: AppColors.entertainmentColor,
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<ReceiptBloc>().add(const ResetReceipt());
                    setState(() => _selectedImage = null);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Scan Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAddExpense(state),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Review & Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Extraction Failed',
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
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  context.read<ReceiptBloc>().add(const ResetReceipt());
                  setState(() => _selectedImage = null);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditExpenseScreen(),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Enter Manually'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final bool disabled;
  final VoidCallback onTap;

  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtractedField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ExtractedField({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDetected = value != 'Not detected';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDetected
                      ? null
                      : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                  fontStyle: isDetected ? null : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Icon(
          isDetected ? Icons.check_circle_rounded : Icons.warning_rounded,
          size: 18,
          color: isDetected ? Colors.green : Colors.orange,
        ),
      ],
    );
  }
}
