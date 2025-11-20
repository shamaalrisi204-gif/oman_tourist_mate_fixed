// lib/screens/ai_chat_screen.dart

import 'package:flutter/material.dart';

import '../core/ai_services.dart';

import '../core/image_service.dart';

import '../core/places_service.dart';

/// نموذج الرسالة (نص + صور)

class ChatMessage {
  final String text;

  final bool isUser;

  final DateTime time;

  final List<String> imageUrls;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.imageUrls = const [],
  });
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ai = AiService();

  final _placesService = PlacesService();

  final TextEditingController _textController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  bool _sending = false;

  bool _isArabicUi = true;

  @override
  void dispose() {
    _textController.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  /// يحدّد نوع المكان من نصّ المستخدم (فنادق / مطاعم / أماكن سياحية)

  String _detectPlaceType(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('hotel') ||
        lower.contains('فنادق') ||
        lower.contains('فندق')) {
      return 'lodging'; // فنادق
    }

    if (lower.contains('restaurant') ||
        lower.contains('مطعم') ||
        lower.contains('أكل') ||
        lower.contains('اكل')) {
      return 'restaurant'; // مطاعم
    }

    // أماكن سياحية عامة

    return 'tourist_attraction';
  }

  /// يكتشف المدينة من النص (مسقط، صحار، صلالة، نزوى...)

  String? _detectCity(String text) {
    final lower = text.toLowerCase();

    final Map<String, List<String>> cityKeywords = {
      'Muscat': ['muscat', 'مسقط'],
      'Sohar': ['sohar', 'صحار'],
      'Salalah': ['salalah', 'صلالة', 'صلاله'],
      'Nizwa': ['nizwa', 'نزوى'],
      'Sur': ['sur', 'صور'],
      'Rustaq': ['rustaq', 'الرستاق'],
      'Barka': ['barka', 'بركاء', 'بركا'],
      'Ibri': ['ibri', 'عبري'],
      'Buraimi': ['buraimi', 'البريمي'],
      'Khasab': ['khasab', 'خصب'],
      'Masirah': ['masirah', 'مصيرة'],
    };

    for (final entry in cityKeywords.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) {
          return entry.key; // نرجّع اسم المدينة بالإنجليزي لـ Google
        }
      }
    }

    return null; // ما لقينا مدينة
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();

    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;

      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          time: DateTime.now(),
        ),
      );

      _textController.clear();
    });

    _scrollToBottom();

    try {
      // (1) رد Gemini (نص الخطة / المعلومات)

      final aiResponse = await _ai.sendMessage(text);

      // (2) جلب صور حقيقية من Google Places حسب المدينة + نوع المكان

      List<String> imageUrls = [];

      final city = _detectCity(text);

      final placeType = _detectPlaceType(text);

      if (city != null) {
        final results = await _placesService.searchPlaces(
          city: city,
          type: placeType,
        );

        imageUrls = results
            .where((p) => p.photoUrl != null)
            .map((p) => p.photoUrl!)
            .toList();
      }

      // (3) لو ما لقينا صور في Google Places → نستخدم Unsplash

      if (imageUrls.isEmpty) {
        final imgQuery = ImageService.queryFromUserText(text);

        // ⚠️ مهم: لا تستخدم "final imageUrls" هنا عشان لا نغطي على المتغيّر فوق

        imageUrls = await ImageService.searchImages(imgQuery);
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: aiResponse,
            isUser: false,
            time: DateTime.now(),
            imageUrls: imageUrls,
          ),
        );

        _sending = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'صار خطأ أثناء جلب الرد أو الصور: $e\nحاولي مرة ثانية بعد قليل 🙏',
            isUser: false,
            time: DateTime.now(),
          ),
        );

        _sending = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _isArabicUi ? '✨ مساعد رحلتك الذكي' : '✨ Your smart trip assistant';

    final inputHint = _isArabicUi
        ? 'اكتبي سؤالك هنا (مثلاً: فنادق في صحار مع صور).. ✍️'
        : 'Ask anything (e.g. hotels in Sohar with pictures)… ✍️';

    return Directionality(
      textDirection: _isArabicUi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        // خلفية بسيطة قريبة من الواتساب

        backgroundColor: const Color(0xFFE5DDD5),

        appBar: AppBar(
          backgroundColor: const Color(0xFF075E54),
          elevation: 0,
          title: Text(
            title,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                setState(() => _isArabicUi = !_isArabicUi);
              },
            ),
            const SizedBox(width: 4),
          ],
        ),

        body: Stack(
          children: [
            // لو حبيتي تضيفي خلفية صورة للشات، تقدرين تبدلين هذا:

            // Image.asset('assets/images/chat_bg.png', fit: BoxFit.cover)

            // مع التأكد من إضافة الصورة للـ pubspec.yaml

            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE5DDD5),
                      Color(0xFFD7C8B6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // الرسائل

                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];

                      final isUser = msg.isUser;

                      final bubbleColor = isUser
                          ? const Color(0xFF128C7E) // أخضر للمستخدم

                          : const Color(0xFFFFFFFF); // أبيض للـ AI

                      final textColor = isUser ? Colors.white : Colors.black87;

                      final align =
                          isUser ? Alignment.centerRight : Alignment.centerLeft;

                      return Align(
                        alignment: align,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.80,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                msg.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'Tajawal',
                                  fontSize: 14.5,
                                  height: 1.5,
                                ),
                              ),

                              // الصور تحت الرد

                              if (msg.imageUrls.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                for (final img in msg.imageUrls)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AspectRatio(
                                        aspectRatio: 4 / 3,
                                        child: Image.network(
                                          img,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: Colors.grey.shade300,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.broken_image,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // شريط الكتابة

                SafeArea(
                  top: false,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 4,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _textController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: inputHint,
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              _sending ? Colors.grey : const Color(0xFF128C7E),
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.send,
                                      color: Colors.white, size: 18),
                                  onPressed: _sendMessage,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
