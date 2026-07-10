import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  _ChatMessage(this.text, this.isUser, {this.isError = false});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  Future<void> _ask() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(question, true));
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final res = await ApiService.queryDocuments(question);
      setState(() {
        _messages.add(_ChatMessage(res['answer'] ?? 'No answer returned.', false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage('Something went wrong answering that.', false, isError: true));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Ask anything about your uploaded documents.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildBubble('Thinking…', false);
                    }
                    final m = _messages[index];
                    return _buildBubble(m.text, m.isUser, isError: m.isError);
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Summarize chapter 2...',
                  ),
                  onSubmitted: (_) => _ask(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _loading ? null : _ask,
                child: const Text('Ask', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(String text, bool isUser, {bool isError = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.purple
              : (isError ? Colors.red.shade900.withOpacity(0.3) : AppColors.cardDark),
          borderRadius: BorderRadius.circular(14),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : (isError ? Colors.redAccent : AppColors.textPrimary),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}