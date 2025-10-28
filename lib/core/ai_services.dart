import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/secrets.dart';

class AiService {
  final GenerativeModel _model;
  AiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash', // أو gemini-2.5-pro حسب حاجتك
          apiKey: Secrets.geminiApiKey,
        );
  Future<String> sendMessage(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      return response.text ?? "لم يتم توليد رد ❌";
    } catch (e) {
      return "حدث خطأ: $e";
    }
  }
}
