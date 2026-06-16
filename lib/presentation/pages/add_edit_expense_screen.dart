import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/expense.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_event.dart';
import '../blocs/receipt/receipt_bloc.dart';
import '../blocs/receipt/receipt_event.dart';
import '../blocs/receipt/receipt_state.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  /// Pre-fill data from receipt scan
  final String? prefillMerchant;
  final double? prefillAmount;
  final DateTime? prefillDate;
  final String? prefillCategory;
  final String? prefillPaymentMethod;
  final double? prefillTax;
  final double? prefillConfidence;

  const AddEditExpenseScreen({
    super.key,
    this.expense,
    this.prefillMerchant,
    this.prefillAmount,
    this.prefillDate,
    this.prefillCategory,
    this.prefillPaymentMethod,
    this.prefillTax,
    this.prefillConfidence,
  });

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late TextEditingController _taxController;
  late TextEditingController _tagController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedPayment;
  late List<String> _tags;

  // Scanner integrations
  int _selectedTab = 0;
  File? _receiptImage;
  final _imagePicker = ImagePicker();

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;
    _merchantController = TextEditingController(
      text: expense?.merchantName ?? widget.prefillMerchant ?? '',
    );
    _amountController = TextEditingController(
      text:
          expense?.amount.toString() ??
          (widget.prefillAmount != null && widget.prefillAmount! > 0
              ? widget.prefillAmount!.toStringAsFixed(2)
              : ''),
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _taxController = TextEditingController(
      text: (expense?.tax ?? widget.prefillTax)?.toStringAsFixed(2) ?? '',
    );
    _tagController = TextEditingController();
    _selectedDate = expense?.date ?? widget.prefillDate ?? DateTime.now();
    _selectedCategory =
        expense?.category ??
        widget.prefillCategory ??
        AppConstants.categories.first;
    _selectedPayment =
        expense?.paymentMethod ??
        widget.prefillPaymentMethod ??
        AppConstants.paymentMethods.first;
    _tags = List<String>.from(expense?.tags ?? _autoGenerateTags());

    // Reset ReceiptBloc to ensure a clean state
    context.read<ReceiptBloc>().add(const ResetReceipt());
  }

  List<String> _autoGenerateTags() {
    final merchant = widget.prefillMerchant ?? '';
    final category = widget.prefillCategory ?? '';
    final tags = <String>[];
    if (category.isNotEmpty) tags.add('#${category.toLowerCase()}');
    if (merchant.isNotEmpty) {
      tags.add('#${merchant.toLowerCase().replaceAll(' ', '_')}');
    }
    return tags;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _taxController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addTag(String tag) {
    final formatted = tag.trim().startsWith('#')
        ? tag.trim()
        : '#${tag.trim()}';
    if (formatted.length > 1 && !_tags.contains(formatted)) {
      setState(() => _tags.add(formatted));
    }
    _tagController.clear();
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;

    // Auto-generate tags from category if empty
    if (_tags.isEmpty) {
      _tags.add('#${_selectedCategory.toLowerCase()}');
    }

    final tax = _taxController.text.trim().isNotEmpty
        ? double.tryParse(_taxController.text.trim())
        : null;

    final expense = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      merchantName: _merchantController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate,
      category: _selectedCategory,
      notes: _notesController.text.trim(),
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
      tags: _tags,
      paymentMethod: _selectedPayment,
      tax: tax,
      receiptPath: widget.expense?.receiptPath,
      confidenceScore:
          widget.expense?.confidenceScore ?? widget.prefillConfidence,
    );

    if (_isEditing) {
      context.read<ExpenseBloc>().add(UpdateExpenseEvent(expense));
    } else {
      context.read<ExpenseBloc>().add(AddExpenseEvent(expense));
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Expense updated successfully!'
              : 'Expense added successfully!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteExpense() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete "${widget.expense!.merchantName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ExpenseBloc>().add(
                DeleteExpenseEvent(widget.expense!.id),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _receiptImage = File(image.path));
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

  Widget _buildScanTab(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    ReceiptState state,
  ) {
    final isLoading = state is ReceiptLoading;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // AI scanner introductory card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'AI Receipt Autofill',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan or upload a receipt image, and our Gemini AI will automatically extract merchant, amount, category, date, payment method, and tax details for you!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.6,
                  ),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons Row (Camera & Gallery)
        Row(
          children: [
            Expanded(
              child: _ScanOptionCard(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                subtitle: 'Take photo',
                gradient: AppColors.primaryGradient,
                disabled: isLoading,
                onTap: () => _pickReceipt(ImageSource.camera),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScanOptionCard(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                subtitle: 'Choose image',
                gradient: AppColors.secondaryGradient,
                disabled: isLoading,
                onTap: () => _pickReceipt(ImageSource.gallery),
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Image Preview or loading state
        if (_receiptImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.file(
                  _receiptImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Loading state descriptive card
        if (isLoading) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemini is scanning...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Extracting details from the receipt image...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Error message if scan failed
        if (state is ReceiptFailure) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.message,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ReceiptBloc, ReceiptState>(
      listener: (context, state) {
        if (state is ReceiptSuccess) {
          final data = state.receiptData;
          setState(() {
            _merchantController.text = data.merchantName;
            _amountController.text = data.amount > 0
                ? data.amount.toStringAsFixed(2)
                : '';
            _taxController.text = data.tax?.toStringAsFixed(2) ?? '';
            _selectedDate = data.date ?? DateTime.now();

            // Safe categories assignment
            _selectedCategory = AppConstants.categories.contains(data.category)
                ? data.category
                : AppConstants.categories.first;

            // Safe payment method assignment
            _selectedPayment =
                AppConstants.paymentMethods.contains(data.paymentMethod)
                ? data.paymentMethod
                : AppConstants.paymentMethods.first;

            _tags = [
              '#${data.category.toLowerCase()}',
              if (data.merchantName.isNotEmpty)
                '#${data.merchantName.toLowerCase().replaceAll(' ', '_')}',
            ];

            // Clear loading states and return to type mode
            _selectedTab = 0;
            _receiptImage = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI Receipt Scan Successful! Fields autofilled.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.primaryContainer,
              duration: const Duration(seconds: 4),
            ),
          );

          // Reset the global state so it's clean for subsequent inputs
          context.read<ReceiptBloc>().add(const ResetReceipt());
        }
      },
      builder: (context, state) {
        final isLoading = state is ReceiptLoading;

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: _deleteExpense,
                ),
            ],
          ),
          body: Column(
            children: [
              // Segmented Toggle at the top (Only if adding a new expense)
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            label: 'Type Manually',
                            icon: Icons.keyboard_rounded,
                            isActive: _selectedTab == 0,
                            onTap: () {
                              if (!isLoading) {
                                setState(() => _selectedTab = 0);
                              }
                            },
                            theme: theme,
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            label: 'AI Scan / Upload',
                            icon: Icons.auto_awesome_rounded,
                            isActive: _selectedTab == 1,
                            onTap: () {
                              if (!isLoading) {
                                setState(() => _selectedTab = 1);
                              }
                            },
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: _selectedTab == 1 && !_isEditing
                    ? _buildScanTab(context, theme, isDark, state)
                    : Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Confidence Badge (if from receipt scan)
                            if (widget.prefillConfidence != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI Confidence: ${(widget.prefillConfidence! * 100).round()}%',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.green,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                            // Merchant Name
                            _FieldLabel(label: 'Merchant Name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _merchantController,
                              decoration: const InputDecoration(
                                hintText: 'e.g., Starbucks, Amazon',
                                prefixIcon: Icon(Icons.store_rounded, size: 20),
                              ),
                              validator: Validators.validateMerchantName,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 18),

                            // Amount + Tax Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel(label: 'Amount'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _amountController,
                                        decoration: InputDecoration(
                                          hintText: '0.00',
                                          prefixIcon: Container(
                                            width: 48,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '₹',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        validator: Validators.validateAmount,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel(label: 'Tax (Optional)'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _taxController,
                                        decoration: const InputDecoration(
                                          hintText: '0.00',
                                          prefixIcon: Icon(
                                            Icons.receipt_outlined,
                                            size: 18,
                                          ),
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Date
                            _FieldLabel(label: 'Date'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _selectDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.dividerColor),
                                  borderRadius: BorderRadius.circular(12),
                                  color: theme.inputDecorationTheme.fillColor,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_selectedDate),
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Category + Payment Method
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel(label: 'Category'),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        key: ValueKey(_selectedCategory),
                                        initialValue: _selectedCategory,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.category_rounded,
                                            size: 18,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                        items: AppConstants.categories.map((
                                          cat,
                                        ) {
                                          return DropdownMenuItem(
                                            value: cat,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.getCategoryColor(
                                                          cat,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  cat,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(
                                              () => _selectedCategory = value,
                                            );
                                          }
                                        },
                                        validator: Validators.validateCategory,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel(label: 'Payment'),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        key: ValueKey(_selectedPayment),
                                        initialValue: _selectedPayment,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            AppColors.getPaymentIcon(
                                              _selectedPayment,
                                            ),
                                            size: 18,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                        ),
                                        items: AppConstants.paymentMethods.map((
                                          m,
                                        ) {
                                          return DropdownMenuItem(
                                            value: m,
                                            child: Text(
                                              m,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(
                                              () => _selectedPayment = value,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Tags
                            _FieldLabel(label: 'Tags'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ..._tags.map(
                                  (tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 14,
                                    ),
                                    onDeleted: () =>
                                        setState(() => _tags.remove(tag)),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: TextField(
                                    controller: _tagController,
                                    decoration: const InputDecoration(
                                      hintText: 'Add tag...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      isDense: true,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                    onSubmitted: _addTag,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Notes
                            _FieldLabel(label: 'Notes (Optional)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                hintText: 'Add a note...',
                                prefixIcon: Icon(Icons.notes_rounded, size: 20),
                              ),
                              maxLines: 3,
                              validator: Validators.validateNotes,
                            ),
                            const SizedBox(height: 28),

                            // Save Button
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _saveExpense,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isEditing
                                          ? Icons.check_rounded
                                          : Icons.add_rounded,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEditing
                                          ? 'Update Expense'
                                          : 'Save Expense',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}

// ─── Scanner Option Card ───
class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final bool disabled;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ScanOptionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.disabled,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.5,
                    ),
                    fontSize: 10,
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

// ─── Segmented Tab Button ───
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
