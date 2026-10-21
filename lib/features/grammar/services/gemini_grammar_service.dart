import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service interfacing with Google Gemini AI (`gemini-1.5-flash`)
/// to correct grammar, typos, and syntax errors on demand.
class GeminiGrammarService {
  final GenerativeModel _model;

  GeminiGrammarService({String? apiKey})
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '',
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.2,
          ),
          systemInstruction: Content.system(
            ' grammar, spelling, and phrasing assistant. '
            'Analyze the provided text. Correct all spelling errors, grammatical mistakes, '
            'punctuation, and awkward phrasing while preserving the user\'s tone and intended meaning. '
            'Return your response STRICTLY as valid JSON in this schema:\n'
            '{\n'
            '  "corrected_text": "<full corrected string>"\n'
            '}\n'
            'Do not wrap the output in markdown code blocks or add explanations outside the JSON.',
          ),
        );

  /// Corrects grammar and spelling for the provided [originalText].
  /// Returns the corrected text string parsed from JSON, or null on failure.
  Future<String?> fixGrammar(String originalText) async {
    final trimmed = originalText.trim();
    if (trimmed.isEmpty) return originalText;

    try {
      final prompt = 'Original text:\n$trimmed';
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        debugPrint('GeminiGrammarService: empty response received.');
        return null;
      }

      // Parse JSON response
      final decoded = jsonDecode(responseText);
      if (decoded is Map<String, dynamic> && decoded.containsKey('corrected_text')) {
        final corrected = decoded['corrected_text']?.toString();
        return corrected;
      }

      debugPrint('GeminiGrammarService: unexpected JSON structure: $responseText');
      return null;
    } catch (e, stack) {
      debugPrint('GeminiGrammarService error: $e\n$stack');
      return null;
    }
  }
}
