// lib/screens/ai_chat_screen.dart

import 'package:flutter/material.dart';

import '../core/ai_services.dart';

import '../core/image_service.dart';

import '../data/tourism_repository.dart';

import '../models/ai_place_suggestion.dart';

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

  final _repo = TourismRepository.I;

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

  // ------------ كشف نوع المكان من نص المستخدم ------------

  String _detectPlaceType(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('hotel') ||
        lower.contains('فنادق') ||
        lower.contains('فندق')) {
      return 'lodging';
    }

    if (lower.contains('restaurant') ||
        lower.contains('مطعم') ||
        lower.contains('أكل') ||
        lower.contains('اكل')) {
      return 'restaurant';
    }

    return 'tourist_attraction';
  }

  // نوع السكن داخل الفنادق: hotel أو resort (اختياري)

  String? _detectLodgingCategory(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('منتجع') || lower.contains('resort')) return 'resort';

    if (lower.contains('فندق') || lower.contains('hotel')) return 'hotel';

    return null;
  }

  // ------------ كشف المدينة ------------

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
          return entry.key; // نرجّع اسم المدينة بالإنجليزي
        }
      }
    }

    return null; // ما لقينا مدينة
  }

  // ------------ عرض صورة (assets أو Network) ------------

  Widget _chatImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
    );
  }

  // ------------ إرسال الرسالة + ربطها مع CSV ------------

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();

    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;

      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));

      _textController.clear();
    });

    _scrollToBottom();

    try {
      // 1) رد الذكاء الاصطناعي (النص)

      final aiResponse = await _ai.sendMessage(text);

      // 2) نحدد نوع المكان والمدينة

      final placeType = _detectPlaceType(text);

      final city = _detectCity(text);

      final category =
          placeType == 'lodging' ? _detectLodgingCategory(text) : null;

      // 3) نجيب بيانات حقيقية من CSV عبر TourismRepository

      List<String> imageUrls = [];

      List<AiPlaceSuggestion> places = [];

      if (placeType == 'lodging') {
        // فنادق / منتجعات من accommodations.csv فقط

        places = await _repo.searchAccommodations(
          city: city,
          category: category,
        );
      } else if (placeType == 'tourist_attraction') {
        // أماكن سياحية من attractions.csv

        places = await _repo.searchAttractions(city: city);
      } else {
        // مطاعم (ما عندنا CSV حالياً) -> نخلي places فاضية

        places = [];
      }

      imageUrls =
          places.map((p) => p.imageUrl).where((url) => url.isNotEmpty).toList();

      // 4) لو ما حصلنا صور من CSV نستخدم ImageService

      if (imageUrls.isEmpty) {
        final imgQuery = ImageService.queryFromUserText(text);

        imageUrls = await ImageService.searchImages(imgQuery);
      }

      // 5) نص نضيفه تحت رد الـ AI (اختياري)

      String finalText = aiResponse;

      if (places.isNotEmpty) {
        finalText +=
            "\n\nهذه بعض الاقتراحات الحقيقية من قاعدة البيانات لدينا:\n" +
                places
                    .take(3)
                    .map((p) => "• ${p.displayName} (${p.city})")
                    .join("\n");
      }

      setState(() {
        _messages.add(ChatMessage(
          text: finalText,
          isUser: false,
          time: DateTime.now(),
          imageUrls: imageUrls,
        ));

        _sending = false;
      });
    } catch (e, st) {
      // ignore: avoid_print

      print('ERROR in _sendMessage: $e\n$st');

      setState(() {
        _messages.add(ChatMessage(
          text: 'صار خطأ أثناء جلب البيانات: $e\nحاولي مرة ثانية 🙏',
          isUser: false,
          time: DateTime.now(),
        ));

        _sending = false;
      });
    }

    _scrollToBottom();
  }

  // ------------ الواجهة ------------

  @override
  Widget build(BuildContext context) {
    final title =
        _isArabicUi ? '✨ مساعد رحلتك الذكي' : '✨ Your smart trip assistant';

    final inputHint = _isArabicUi
        ? 'اكتبي سؤالك هنا… (مثلاً: فنادق في مسقط مع صور)'
        : 'Ask anything… (example: hotels in Muscat with pictures)';

    return Directionality(
      textDirection: _isArabicUi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFE5DDD5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF075E54),
          title: Text(title, style: const TextStyle(fontFamily: 'Tajawal')),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                setState(() => _isArabicUi = !_isArabicUi);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // الرسائل

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final msg = _messages[i];

                  final isUser = msg.isUser;

                  final bubbleColor =
                      isUser ? const Color(0xFF128C7E) : Colors.white;

                  final textColor = isUser ? Colors.white : Colors.black87;

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
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
                          if (msg.imageUrls.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            for (final url in msg.imageUrls)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: _chatImage(url),
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

            // شريط إدخال الرسالة

            SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: const Color(0xFFEEEEEE),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          _sending ? Colors.grey : const Color(0xFF128C7E),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
