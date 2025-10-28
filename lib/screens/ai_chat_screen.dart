import 'package:flutter/material.dart';
import '../core/ai_services.dart'; // مسار الخدمة الخاصة بالـ Gemini

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiService _aiService = AiService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _busy = false;
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _messages.add({"role": "user", "text": text});
      _controller.clear();
      _busy = true;
    });
    try {
      final reply = await _aiService.sendMessage(text);
      setState(() {
        _messages.add({"role": "ai", "text": reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "text": "⚠️ حدث خطأ: $e"});
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        centerTitle: true,
        title: const Text(
          "رحلة ممتعة تبدأ من هنا ✨",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "✍️ اكتب سؤالك هنا...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: _busy
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
