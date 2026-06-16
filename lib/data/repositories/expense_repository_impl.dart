import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDatasource localDatasource;

  const ExpenseRepositoryImpl({required this.localDatasource});

  @override
  Future<List<Expense>> getAllExpenses() async {
    try {
      final models = await localDatasource.getAllExpenses();
      return models.map((m) => m.toEntity()).toList();
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await localDatasource.addExpense(model);
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await localDatasource.updateExpense(model);
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await localDatasource.deleteExpense(id);
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }
}
