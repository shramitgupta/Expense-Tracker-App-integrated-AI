import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final String merchantName;
  final double amount;
  final DateTime date;
  final String category;
  final String notes;
  final DateTime createdAt;
  final List<String> tags;
  final String paymentMethod;
  final double? tax;
  final String? receiptPath;
  final double? confidenceScore;

  const Expense({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
    this.notes = '',
    required this.createdAt,
    this.tags = const [],
    this.paymentMethod = 'Cash',
    this.tax,
    this.receiptPath,
    this.confidenceScore,
  });

  Expense copyWith({
    String? id,
    String? merchantName,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
    DateTime? createdAt,
    List<String>? tags,
    String? paymentMethod,
    double? tax,
    String? receiptPath,
    double? confidenceScore,
  }) {
    return Expense(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tax: tax ?? this.tax,
      receiptPath: receiptPath ?? this.receiptPath,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  @override
  List<Object?> get props => [
        id,
        merchantName,
        amount,
        date,
        category,
        notes,
        createdAt,
        tags,
        paymentMethod,
        tax,
        receiptPath,
        confidenceScore,
      ];
}
