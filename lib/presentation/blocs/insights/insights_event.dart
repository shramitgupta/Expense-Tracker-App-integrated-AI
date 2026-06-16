import 'package:equatable/equatable.dart';

abstract class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object?> get props => [];
}

class GenerateInsightsEvent extends InsightsEvent {
  final List<Map<String, dynamic>> expenses;
  const GenerateInsightsEvent(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class ResetInsights extends InsightsEvent {
  const ResetInsights();
}
