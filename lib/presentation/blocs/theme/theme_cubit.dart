import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class ThemeCubit extends Cubit<bool> {
  final Box _settingsBox;

  // false = light, true = dark. Reads the value from the settings box, defaulting to light mode (false).
  ThemeCubit(this._settingsBox) : super(_settingsBox.get('is_dark', defaultValue: false) as bool);

  void toggleTheme() {
    final newValue = !state;
    _settingsBox.put('is_dark', newValue);
    emit(newValue);
  }

  void setDarkMode(bool isDark) {
    _settingsBox.put('is_dark', isDark);
    emit(isDark);
  }

  bool get isDark => state;
}
