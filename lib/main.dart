import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/color_constants.dart';
import 'injection_container.dart';
import 'presentation/blocs/coach/coach_bloc.dart';
import 'presentation/blocs/expense/expense_bloc.dart';
import 'presentation/blocs/insights/insights_bloc.dart';
import 'presentation/blocs/receipt/receipt_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching — use bundled/system fonts as fallback
  GoogleFonts.config.allowRuntimeFetching = false;

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependencies
  await initDependencies();

  runApp(const ExpenseIQApp());
}

class ExpenseIQApp extends StatelessWidget {
  const ExpenseIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => sl<ThemeCubit>(),
        ),
        BlocProvider<ExpenseBloc>(
          create: (_) => sl<ExpenseBloc>(),
        ),
        BlocProvider<ReceiptBloc>(
          create: (_) => sl<ReceiptBloc>(),
        ),
        BlocProvider<InsightsBloc>(
          create: (_) => sl<InsightsBloc>(),
        ),
        BlocProvider<CoachBloc>(
          create: (_) => sl<CoachBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDark) {
          SystemChrome.setSystemUIOverlayStyle(
            isDark
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: AppColors.surfaceDark,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.white,
                  ),
          );

          return MaterialApp(
            title: 'AI Expense tracker APP',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
