// lib/core/ai_services.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'secrets.dart';

/// خدمة الذكاء الاصطناعي (Gemini)
class AiService {
  final GenerativeModel _model;

  AiService()
      : _model = GenerativeModel(
          // لو حبيتي تقدري تبدلي لـ gemini-1.5-flash-latest
          model: 'gemini-2.5-pro',
          apiKey: Secrets.geminiApiKey,
          generationConfig: GenerationConfig(
            maxOutputTokens: 2048, // نص طويل وواضح
            temperature: 0.8,
          ),
        );

  /// إرسال رسالة للنموذج وترجيع نص الرد فقط
  Future<String> sendMessage(String userMessage) async {
    try {
      // تعليمات للنموذج عشان يرد كنظام سياحي لعُمان
      final systemInstruction = Content.text(
        '''
أنت مساعد سياحي ذكي متخصص في سلطنة عُمان.
- جاوب بالعربية أو الإنجليزية حسب لغة سؤال المستخدم لوحدك.
- قدّم خطط سفر، اقتراحات فنادق، أماكن سياحية، مطاعم، أنشطة، نصائح.
- قسّم الرد إلى فقرات وعناوين فرعية وخطوط نقطية ليسهل قراءته.
- تجنّب الردود القصيرة جداً، وحاول أن يكون الرد غني بالمعلومات لكن بدون حشو زائد.
- لا تذكر أن الصور غير متاحة، لأن التطبيق يعرض صوراً من خدمات أخرى.
        ''',
      );

      final userContent = Content.text(userMessage);

      final response = await _model.generateContent(
        [systemInstruction, userContent],
      );

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return 'لم يتم توليد رد، حاول صياغة سؤالك بشكل أوضح 😊';
      }
      return text;
    } catch (e) {
      return 'حدث خطأ أثناء التواصل مع خدمة الذكاء الاصطناعي: $e';
    }
  }
}
