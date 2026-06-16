import 'package:equatable/equatable.dart';

abstract class CoachEvent extends Equatable {
  const CoachEvent();

  @override
  List<Object?> get props => [];
}

class GenerateCoachAdvice extends CoachEvent {
  final List<Map<String, dynamic>> expenses;
  const GenerateCoachAdvice(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class GenerateHealthScore extends CoachEvent {
  final List<Map<String, dynamic>> expenses;
  const GenerateHealthScore(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class GenerateAlerts extends CoachEvent {
  final List<Map<String, dynamic>> expenses;
  const GenerateAlerts(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class ResetCoach extends CoachEvent {
  const ResetCoach();
}
