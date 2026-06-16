import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

abstract class ExpenseLocalDatasource {
  Future<List<ExpenseModel>> getAllExpenses();
  Future<void> addExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
}

class ExpenseLocalDatasourceImpl implements ExpenseLocalDatasource {
  final Box<ExpenseModel> _expenseBox;

  ExpenseLocalDatasourceImpl(this._expenseBox);

  static Future<Box<ExpenseModel>> openBox() async {
    return await Hive.openBox<ExpenseModel>(AppConstants.hiveExpenseBox);
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      final expenses = _expenseBox.values.toList();
      // Sort by date descending by default
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    } catch (e) {
      throw CacheException('Failed to load expenses: ${e.toString()}');
    }
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _expenseBox.put(expense.id, expense);
    } catch (e) {
      throw CacheException('Failed to save expense: ${e.toString()}');
    }
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      if (!_expenseBox.containsKey(expense.id)) {
        throw const CacheException('Expense not found.');
      }
      await _expenseBox.put(expense.id, expense);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to update expense: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      if (!_expenseBox.containsKey(id)) {
        throw const CacheException('Expense not found.');
      }
      await _expenseBox.delete(id);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to delete expense: ${e.toString()}');
    }
  }
}
