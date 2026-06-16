import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

// ─── Receipt Data ───
class ReceiptData {
  final String merchantName;
  final double amount;
  final DateTime? date;
  final String category;
  final double? tax;
  final String paymentMethod;
  final String currency;
  final double confidenceScore;

  const ReceiptData({
    required this.merchantName,
    required this.amount,
    this.date,
    required this.category,
    this.tax,
    this.paymentMethod = 'Cash',
    this.currency = 'INR',
    this.confidenceScore = 0.0,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    double parsedAmount = 0.0;
    final amountValue = json['amount'];
    if (amountValue is num) {
      parsedAmount = amountValue.toDouble();
    } else if (amountValue is String) {
      final cleaned = amountValue.replaceAll(RegExp(r'[^\d.]'), '');
      parsedAmount = double.tryParse(cleaned) ?? 0.0;
    }

    double? parsedTax;
    final taxValue = json['tax'];
    if (taxValue is num) {
      parsedTax = taxValue.toDouble();
    } else if (taxValue is String) {
      final cleaned = taxValue.replaceAll(RegExp(r'[^\d.]'), '');
      parsedTax = double.tryParse(cleaned);
    }

    DateTime? parsedDate;
    final dateValue = json['date'];
    if (dateValue is String && dateValue.isNotEmpty) {
      parsedDate = _tryParseDate(dateValue);
    }

    double confidence = 0.0;
    final confValue = json['confidence_score'];
    if (confValue is num) {
      confidence = confValue.toDouble().clamp(0.0, 1.0);
    }

    return ReceiptData(
      merchantName: (json['merchant_name'] as String?) ?? '',
      amount: parsedAmount,
      date: parsedDate,
      category: _mapCategory((json['category'] as String?) ?? 'Others'),
      tax: parsedTax,
      paymentMethod: (json['payment_method'] as String?) ?? 'Cash',
      currency: (json['currency'] as String?) ?? 'INR',
      confidenceScore: confidence,
    );
  }

  static DateTime? _tryParseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      final patterns = [
        RegExp(r'(\d{2})/(\d{2})/(\d{4})'),
        RegExp(r'(\d{2})-(\d{2})-(\d{4})'),
      ];
      for (final pattern in patterns) {
        final match = pattern.firstMatch(dateStr);
        if (match != null) {
          try {
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(2)!),
              int.parse(match.group(1)!),
            );
          } catch (_) {
            continue;
          }
        }
      }
      return null;
    }
  }

  static String _mapCategory(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('food') ||
        lower.contains('restaurant') ||
        lower.contains('grocery') ||
        lower.contains('dining') ||
        lower.contains('cafe') ||
        lower.contains('swiggy') ||
        lower.contains('zomato')) {
      return 'Food';
    } else if (lower.contains('shop') ||
        lower.contains('retail') ||
        lower.contains('store') ||
        lower.contains('amazon') ||
        lower.contains('flipkart')) {
      return 'Shopping';
    } else if (lower.contains('travel') ||
        lower.contains('transport') ||
        lower.contains('fuel') ||
        lower.contains('cab') ||
        lower.contains('uber') ||
        lower.contains('ola')) {
      return 'Travel';
    } else if (lower.contains('utility') ||
        lower.contains('bill') ||
        lower.contains('electric') ||
        lower.contains('water') ||
        lower.contains('internet') ||
        lower.contains('recharge')) {
      return 'Utilities';
    } else if (lower.contains('entertain') ||
        lower.contains('movie') ||
        lower.contains('game') ||
        lower.contains('music')) {
      return 'Entertainment';
    } else if (lower.contains('health') ||
        lower.contains('medical') ||
        lower.contains('pharmacy') ||
        lower.contains('hospital') ||
        lower.contains('doctor')) {
      return 'Health';
    } else if (lower.contains('education') ||
        lower.contains('course') ||
        lower.contains('book') ||
        lower.contains('tuition')) {
      return 'Education';
    } else if (lower.contains('subscription') ||
        lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('youtube') ||
        lower.contains('premium')) {
      return 'Subscription';
    } else {
      return 'Others';
    }
  }
}

// ─── Gemini Service ───
class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: ApiConstants.geminiModel,
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  /// Extract receipt data from an image file (Pro version)
  Future<ReceiptData> extractReceipt(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final mimeType = _getMimeType(imageFile.path);

      final prompt = TextPart(
        'Analyze this receipt image and extract structured data.\n\n'
        'Return ONLY valid JSON with these fields:\n'
        '{\n'
        '"merchant_name": "store/restaurant name",\n'
        '"amount": numeric_total_amount,\n'
        '"date": "YYYY-MM-DD",\n'
        '"category": "Food|Shopping|Travel|Utilities|Entertainment|Health|Education|Subscription|Others",\n'
        '"tax": numeric_tax_amount_or_null,\n'
        '"payment_method": "Cash|UPI|Card|Online",\n'
        '"currency": "INR|USD|EUR",\n'
        '"confidence_score": 0.0_to_1.0_how_confident_you_are\n'
        '}\n\n'
        'Rules:\n'
        '- amount: total payable, numeric only\n'
        '- date: YYYY-MM-DD format\n'
        '- confidence_score: 0.0 to 1.0 based on image clarity\n'
        '- If a field is unclear, use best guess and lower confidence\n'
        '- No markdown, no explanations',
      );

      final imagePart = DataPart(mimeType, imageBytes);

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart]),
      ]).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const AIExtractionException(
          'Request timed out. Please try again.',
        ),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const AIExtractionException('Empty response from AI.');
      }

      final jsonString = _extractJson(text);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      return ReceiptData.fromJson(json);
    } on AIExtractionException {
      rethrow;
    } on FormatException {
      throw const AIExtractionException(
        'Could not parse receipt data. Invalid format received.',
      );
    } catch (e) {
      throw AIExtractionException(
        'Could not extract receipt information: ${e.toString()}',
      );
    }
  }

  /// Generate spending insights from expense data
  Future<String> generateInsights(List<Map<String, dynamic>> expenses) async {
    try {
      final expenseJson = jsonEncode(expenses);

      final prompt = '''
Analyze the following expenses and generate a comprehensive financial summary.

Structure your response with clear sections using ** headers **:

**Overview**
Total spending, number of transactions, date range.

**Category Breakdown**
Top spending categories with amounts and percentages.

**Spending Patterns**
Notable trends, peak spending days, recurring patterns.

**Top Expenses**
The 3 largest individual expenses.

**Recommendations**
3 actionable tips to optimize spending. Be specific with numbers.

Use ₹ as currency symbol. Keep response under 400 words.

Expense Data:
$expenseJson
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const AIInsightsException(
          'Request timed out. Please try again.',
        ),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const AIInsightsException('Empty response from AI.');
      }

      return text;
    } on AIInsightsException {
      rethrow;
    } catch (e) {
      throw AIInsightsException(
        'Could not generate insights: ${e.toString()}',
      );
    }
  }

  /// AI Spending Coach — generates coaching advice
  Future<String> generateCoachAdvice(
    List<Map<String, dynamic>> expenses,
  ) async {
    try {
      final expenseJson = jsonEncode(expenses);

      final prompt = '''
You are a personal AI financial coach. Analyze the user's expenses and provide coaching.

Structure your response with clear sections using ** headers **:

**Financial Strengths**
What the user is doing well (2-3 points).

**Areas of Concern**
Categories or habits that need attention (2-3 points).

**Savings Opportunities**
Specific, actionable savings suggestions with estimated amounts.
Example: "Reducing food delivery by 20% could save approximately ₹X monthly."

**Suggested Monthly Budget**
Recommend a budget for each category based on their spending patterns.
Format: Category: ₹amount

**30-Day Challenge**
One specific challenge to improve financial health.

Use ₹ as currency. Be encouraging but honest. Under 500 words.

Expense Data:
$expenseJson
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw const AIInsightsException(
          'Request timed out. Please try again.',
        ),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const AIInsightsException('Empty coaching response.');
      }

      return text;
    } on AIInsightsException {
      rethrow;
    } catch (e) {
      throw AIInsightsException(
        'Could not generate coaching advice: ${e.toString()}',
      );
    }
  }

  /// Generate Financial Health Score (0-100)
  Future<Map<String, dynamic>> generateHealthScore(
    List<Map<String, dynamic>> expenses,
  ) async {
    try {
      final expenseJson = jsonEncode(expenses);

      final prompt = '''
Analyze these expenses and generate a Financial Health Score.

Return ONLY valid JSON:
{
  "score": 0-100,
  "label": "Excellent|Good|Fair|Needs Work|Critical",
  "breakdown": {
    "spending_consistency": 0-100,
    "category_balance": 0-100,
    "savings_potential": 0-100,
    "expense_control": 0-100
  },
  "summary": "One sentence summary"
}

Scoring criteria:
- spending_consistency: How regular/predictable are expenses
- category_balance: Good distribution across needs vs wants
- savings_potential: Room for savings based on patterns
- expense_control: No sudden spikes or overspending

No markdown. No explanations.

Expense Data:
$expenseJson
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const AIInsightsException(
          'Request timed out.',
        ),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const AIInsightsException('Empty response.');
      }

      final jsonString = _extractJson(text);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } on AIInsightsException {
      rethrow;
    } catch (e) {
      throw AIInsightsException(
        'Could not generate health score: ${e.toString()}',
      );
    }
  }

  /// Generate smart spending alerts
  Future<List<String>> generateAlerts(
    List<Map<String, dynamic>> expenses,
  ) async {
    try {
      final expenseJson = jsonEncode(expenses);

      final prompt = '''
Analyze these expenses and generate spending alerts.

Return ONLY a JSON array of alert strings. Max 5 alerts.
Example: ["Food spending increased by 42% this month", "Shopping exceeded monthly average"]

Focus on:
- Categories with unusual spending
- Large single transactions
- Spending trends that need attention

Use ₹ for amounts. Be concise. No markdown.

Expense Data:
$expenseJson
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw const AIInsightsException('Timed out.'),
      );

      final text = response.text;
      if (text == null || text.isEmpty) return [];

      final jsonString = _extractJson(text);
      final list = jsonDecode(jsonString) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  String _extractJson(String text) {
    final codeBlockMatch =
        RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```').firstMatch(text);
    if (codeBlockMatch != null) {
      return codeBlockMatch.group(1)!.trim();
    }

    // Try array
    final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
    if (arrayMatch != null) {
      return arrayMatch.group(0)!;
    }

    // Try object
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }

    return text.trim();
  }
}
