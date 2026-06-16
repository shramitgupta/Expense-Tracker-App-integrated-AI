import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/gemini_service.dart';
import 'data/datasources/expense_local_datasource.dart';
import 'data/models/expense_model.dart';
import 'data/repositories/expense_repository_impl.dart';
import 'domain/repositories/expense_repository.dart';
import 'domain/usecases/add_expense.dart';
import 'domain/usecases/delete_expense.dart';
import 'domain/usecases/extract_receipt.dart';
import 'domain/usecases/generate_insights.dart';
import 'domain/usecases/get_expenses.dart';
import 'domain/usecases/update_expense.dart';
import 'presentation/blocs/coach/coach_bloc.dart';
import 'presentation/blocs/expense/expense_bloc.dart';
import 'presentation/blocs/insights/insights_bloc.dart';
import 'presentation/blocs/receipt/receipt_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── Hive ───
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseModelAdapter());
  final expenseBox =
      await Hive.openBox<ExpenseModel>('expenses');
  final settingsBox = await Hive.openBox('settings');

  // ─── Services ───
  sl.registerLazySingleton<GeminiService>(() => GeminiService());

  // ─── Data Sources ───
  sl.registerLazySingleton<ExpenseLocalDatasource>(
    () => ExpenseLocalDatasourceImpl(expenseBox),
  );

  // ─── Repositories ───
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(localDatasource: sl()),
  );

  // ─── Use Cases ───
  sl.registerLazySingleton(() => GetExpenses(sl()));
  sl.registerLazySingleton(() => AddExpense(sl()));
  sl.registerLazySingleton(() => UpdateExpense(sl()));
  sl.registerLazySingleton(() => DeleteExpense(sl()));
  sl.registerLazySingleton(() => ExtractReceipt(sl()));
  sl.registerLazySingleton(() => GenerateInsights(sl()));

  // ─── BLoCs ───
  sl.registerFactory(
    () => ExpenseBloc(
      getExpenses: sl(),
      addExpense: sl(),
      updateExpense: sl(),
      deleteExpense: sl(),
    ),
  );

  sl.registerFactory(
    () => ReceiptBloc(extractReceipt: sl()),
  );

  sl.registerFactory(
    () => InsightsBloc(generateInsights: sl()),
  );

  sl.registerFactory(
    () => CoachBloc(geminiService: sl()),
  );

  // ─── Theme ───
  sl.registerLazySingleton(() => ThemeCubit(settingsBox));
}
