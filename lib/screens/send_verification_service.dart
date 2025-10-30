import 'dart:convert';
import 'package:http/http.dart' as http;

class VerificationService {
  // ✅ ضعي رابط Cloud Run الذي ظهر بعد النشر
  static const String baseUrl =
      "https://sendverificationcode-o4g26r2yxq-uc.a.run.app";
  static Future<bool> sendVerificationCode(String email) async {
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "data": {"email": email}
        }),
      );
      if (res.statusCode == 200) return true;
      // لطباعة الخطأ من السيرفر إن وجد
      // print("Server error: ${res.statusCode} ${res.body}");
      return false;
    } catch (e) {
      // print("Http error: $e");
      return false;
    }
  }
}
