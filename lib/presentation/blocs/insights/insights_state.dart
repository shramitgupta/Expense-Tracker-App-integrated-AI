import 'package:equatable/equatable.dart';

abstract class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

class InsightsGenerated extends InsightsState {
  final String report;
  const InsightsGenerated(this.report);

  @override
  List<Object?> get props => [report];
}

class InsightsFailure extends InsightsState {
  final String message;
  const InsightsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
