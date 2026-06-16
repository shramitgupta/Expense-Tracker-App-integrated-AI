import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class UpdateExpense {
  final ExpenseRepository repository;

  const UpdateExpense(this.repository);

  Future<void> call(Expense expense) async {
    return await repository.updateExpense(expense);
  }
}
