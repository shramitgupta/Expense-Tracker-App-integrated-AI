import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/generate_insights.dart';
import '../../../core/errors/exceptions.dart';
import 'insights_event.dart';
import 'insights_state.dart';

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  final GenerateInsights generateInsights;

  InsightsBloc({required this.generateInsights})
      : super(const InsightsInitial()) {
    on<GenerateInsightsEvent>(_onGenerateInsights);
    on<ResetInsights>(_onResetInsights);
  }

  Future<void> _onGenerateInsights(
    GenerateInsightsEvent event,
    Emitter<InsightsState> emit,
  ) async {
    emit(const InsightsLoading());
    try {
      final report = await generateInsights(event.expenses);
      emit(InsightsGenerated(report));
    } on AIInsightsException catch (e) {
      emit(InsightsFailure(e.message));
    } catch (e) {
      emit(InsightsFailure(
        'Could not generate spending insights. Please try again.',
      ));
    }
  }

  void _onResetInsights(
    ResetInsights event,
    Emitter<InsightsState> emit,
  ) {
    emit(const InsightsInitial());
  }
}
