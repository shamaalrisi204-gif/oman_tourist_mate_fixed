import 'dart:convert';
import 'package:http/http.dart' as http;

class OtpService {
  OtpService._();
  static final OtpService I = OtpService._();
  static const String _sendUrl =
      'https://sendverificationcode-o4g26r2yxq-uc.a.run.app';
  static const String _verifyUrl =
      'https://verifyotpcode-o4g26r2yxq-uc.a.run.app';
  Future<bool> sendVerificationCode(String email) async {
    try {
      final res = await http
          .post(
            Uri.parse(_sendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': {'email': email}
            }),
          )
          .timeout(const Duration(seconds: 20));
      // debugPrint('SEND status=${res.statusCode} body=${res.body}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('تعذر الإتصال بالخادم: $e');
    }
  }

  Future<bool> verifyCode(String email, String code) async {
    try {
      final res = await http
          .post(
            Uri.parse(_verifyUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': {'email': email, 'code': code}
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('تعذر الإتصال بالخادم: $e');
    }
  }
}
