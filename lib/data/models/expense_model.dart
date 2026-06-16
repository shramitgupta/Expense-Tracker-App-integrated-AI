import 'package:hive/hive.dart';
import '../../domain/entities/expense.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String merchantName;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String notes;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final List<String> tags;

  @HiveField(8)
  final String paymentMethod;

  @HiveField(9)
  final double? tax;

  @HiveField(10)
  final String? receiptPath;

  @HiveField(11)
  final double? confidenceScore;

  ExpenseModel({
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

  /// Convert from domain entity
  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      merchantName: expense.merchantName,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      notes: expense.notes,
      createdAt: expense.createdAt,
      tags: expense.tags,
      paymentMethod: expense.paymentMethod,
      tax: expense.tax,
      receiptPath: expense.receiptPath,
      confidenceScore: expense.confidenceScore,
    );
  }

  /// Convert to domain entity
  Expense toEntity() {
    return Expense(
      id: id,
      merchantName: merchantName,
      amount: amount,
      date: date,
      category: category,
      notes: notes,
      createdAt: createdAt,
      tags: tags,
      paymentMethod: paymentMethod,
      tax: tax,
      receiptPath: receiptPath,
      confidenceScore: confidenceScore,
    );
  }

  /// Convert to JSON map (for AI insights)
  Map<String, dynamic> toJson() {
    return {
      'merchant_name': merchantName,
      'amount': amount,
      'date': date.toIso8601String().split('T').first,
      'category': category,
      'notes': notes,
      'tags': tags,
      'payment_method': paymentMethod,
      'tax': tax,
    };
  }
}
