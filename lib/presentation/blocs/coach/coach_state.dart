import 'package:equatable/equatable.dart';

abstract class CoachState extends Equatable {
  const CoachState();

  @override
  List<Object?> get props => [];
}

class CoachInitial extends CoachState {
  const CoachInitial();
}

class CoachLoading extends CoachState {
  final String message;
  const CoachLoading({this.message = 'Analyzing...'});

  @override
  List<Object?> get props => [message];
}

class CoachAdviceGenerated extends CoachState {
  final String advice;
  const CoachAdviceGenerated(this.advice);

  @override
  List<Object?> get props => [advice];
}

class HealthScoreGenerated extends CoachState {
  final int score;
  final String label;
  final String summary;
  final Map<String, int> breakdown;

  const HealthScoreGenerated({
    required this.score,
    required this.label,
    required this.summary,
    required this.breakdown,
  });

  @override
  List<Object?> get props => [score, label, summary, breakdown];
}

class AlertsGenerated extends CoachState {
  final List<String> alerts;
  const AlertsGenerated(this.alerts);

  @override
  List<Object?> get props => [alerts];
}

class CoachError extends CoachState {
  final String message;
  const CoachError(this.message);

  @override
  List<Object?> get props => [message];
}
