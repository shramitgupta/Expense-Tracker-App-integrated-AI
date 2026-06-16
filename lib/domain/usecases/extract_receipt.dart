import 'dart:io';

import '../../core/services/gemini_service.dart';

class ExtractReceipt {
  final GeminiService geminiService;

  const ExtractReceipt(this.geminiService);

  Future<ReceiptData> call(File imageFile) async {
    return await geminiService.extractReceipt(imageFile);
  }
}
