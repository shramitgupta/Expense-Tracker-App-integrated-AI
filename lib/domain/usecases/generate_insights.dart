import '../../core/services/gemini_service.dart';

class GenerateInsights {
  final GeminiService geminiService;

  const GenerateInsights(this.geminiService);

  Future<String> call(List<Map<String, dynamic>> expenses) async {
    return await geminiService.generateInsights(expenses);
  }
}
