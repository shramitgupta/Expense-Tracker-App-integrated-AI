import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<bool> {
  // false = light, true = dark
  ThemeCubit() : super(false);

  void toggleTheme() => emit(!state);

  void setDarkMode(bool isDark) => emit(isDark);

  bool get isDark => state;
}
