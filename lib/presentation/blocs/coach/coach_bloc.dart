import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/gemini_service.dart';
import 'coach_event.dart';
import 'coach_state.dart';

class CoachBloc extends Bloc<CoachEvent, CoachState> {
  final GeminiService geminiService;

  CoachBloc({required this.geminiService}) : super(const CoachInitial()) {
    on<GenerateCoachAdvice>(_onGenerateAdvice);
    on<GenerateHealthScore>(_onGenerateHealthScore);
    on<GenerateAlerts>(_onGenerateAlerts);
    on<ResetCoach>(_onReset);
  }

  Future<void> _onGenerateAdvice(
    GenerateCoachAdvice event,
    Emitter<CoachState> emit,
  ) async {
    emit(const CoachLoading(message: 'AI Coach is analyzing your spending...'));
    try {
      final advice = await geminiService.generateCoachAdvice(event.expenses);
      emit(CoachAdviceGenerated(advice));
    } catch (e) {
      emit(CoachError(e.toString()));
    }
  }

  Future<void> _onGenerateHealthScore(
    GenerateHealthScore event,
    Emitter<CoachState> emit,
  ) async {
    emit(const CoachLoading(message: 'Calculating health score...'));
    try {
      final result = await geminiService.generateHealthScore(event.expenses);

      final score = (result['score'] as num?)?.toInt() ?? 50;
      final label = (result['label'] as String?) ?? 'Fair';
      final summary = (result['summary'] as String?) ?? '';
      final breakdownRaw =
          (result['breakdown'] as Map<String, dynamic>?) ?? {};
      final breakdown = breakdownRaw.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );

      emit(HealthScoreGenerated(
        score: score.clamp(0, 100),
        label: label,
        summary: summary,
        breakdown: breakdown,
      ));
    } catch (e) {
      emit(CoachError(e.toString()));
    }
  }

  Future<void> _onGenerateAlerts(
    GenerateAlerts event,
    Emitter<CoachState> emit,
  ) async {
    emit(const CoachLoading(message: 'Checking for alerts...'));
    try {
      final alerts = await geminiService.generateAlerts(event.expenses);
      emit(AlertsGenerated(alerts));
    } catch (e) {
      emit(CoachError(e.toString()));
    }
  }

  void _onReset(ResetCoach event, Emitter<CoachState> emit) {
    emit(const CoachInitial());
  }
}
