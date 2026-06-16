import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/add_expense.dart';
import '../../../domain/usecases/delete_expense.dart';
import '../../../domain/usecases/get_expenses.dart';
import '../../../domain/usecases/update_expense.dart';
import '../../../domain/entities/expense.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final GetExpenses getExpenses;
  final AddExpense addExpense;
  final UpdateExpense updateExpense;
  final DeleteExpense deleteExpense;

  ExpenseBloc({
    required this.getExpenses,
    required this.addExpense,
    required this.updateExpense,
    required this.deleteExpense,
  }) : super(const ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpenseEvent>(_onAddExpense);
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<SearchExpenses>(_onSearchExpenses);
    on<SortExpenses>(_onSortExpenses);
  }

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(const ExpenseLoading());
    try {
      final expenses = await getExpenses();
      emit(ExpenseLoaded(
        expenses: expenses,
        filteredExpenses: expenses,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await addExpense(event.expense);
      add(const LoadExpenses());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await updateExpense(event.expense);
      add(const LoadExpenses());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await deleteExpense(event.id);
      add(const LoadExpenses());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  void _onSearchExpenses(
    SearchExpenses event,
    Emitter<ExpenseState> emit,
  ) {
    final currentState = state;
    if (currentState is ExpenseLoaded) {
      final query = event.query.toLowerCase().trim();
      List<Expense> filtered;

      if (query.isEmpty) {
        filtered = currentState.expenses;
      } else {
        filtered = currentState.expenses.where((expense) {
          return expense.merchantName.toLowerCase().contains(query) ||
              expense.category.toLowerCase().contains(query) ||
              expense.notes.toLowerCase().contains(query);
        }).toList();
      }

      filtered = _sortExpenses(filtered, currentState.sortOption);

      emit(currentState.copyWith(
        filteredExpenses: filtered,
        searchQuery: event.query,
      ));
    }
  }

  void _onSortExpenses(
    SortExpenses event,
    Emitter<ExpenseState> emit,
  ) {
    final currentState = state;
    if (currentState is ExpenseLoaded) {
      final sorted = _sortExpenses(
        List.from(currentState.filteredExpenses),
        event.sortOption,
      );
      emit(currentState.copyWith(
        filteredExpenses: sorted,
        sortOption: event.sortOption,
      ));
    }
  }

  List<Expense> _sortExpenses(List<Expense> expenses, SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
        expenses.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.dateAsc:
        expenses.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.amountDesc:
        expenses.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.amountAsc:
        expenses.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return expenses;
  }
}
