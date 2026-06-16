import 'package:equatable/equatable.dart';
import '../../../domain/entities/expense.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {
  const LoadExpenses();
}

class AddExpenseEvent extends ExpenseEvent {
  final Expense expense;
  const AddExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

class UpdateExpenseEvent extends ExpenseEvent {
  final Expense expense;
  const UpdateExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

class DeleteExpenseEvent extends ExpenseEvent {
  final String id;
  const DeleteExpenseEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SearchExpenses extends ExpenseEvent {
  final String query;
  const SearchExpenses(this.query);

  @override
  List<Object?> get props => [query];
}

enum SortOption { dateDesc, dateAsc, amountDesc, amountAsc }

class SortExpenses extends ExpenseEvent {
  final SortOption sortOption;
  const SortExpenses(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}
