import '../repositories/expense_repository.dart';

class DeleteExpense {
  final ExpenseRepository repository;

  const DeleteExpense(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteExpense(id);
  }
}
