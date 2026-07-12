import 'dart:ui';
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
  final FocusNode _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  static const _suggestions = [
    'Summarize this document',
    'List key points',
    'Explain chapter 1',
    'Give me 5 quiz questions',
  ];

  Future<void> _ask([String? preset]) async {
    final question = (preset ?? _controller.text).trim();
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extra bottom space so content + input never sit under the floating nav bar.
    const navClearance = 108.0;

    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -30,
          child: _blob(AppColors.purple.withOpacity(0.2), 160),
        ),
        Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return _buildThinkingBubble();
                        }
                        final m = _messages[index];
                        return _buildBubble(m.text, m.isUser, isError: m.isError);
                      },
                    ),
            ),
            // Input bar, lifted clear of the floating nav bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, navClearance),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _focusNode.hasFocus ? AppColors.lime : AppColors.border,
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onTap: () => setState(() {}),
                        onTapOutside: (_) => _focusNode.unfocus(),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Ask about your notes…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onSubmitted: (_) => _ask(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    GestureDetector(
                      onTap: _loading ? null : () => _ask(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _controller.text.trim().isEmpty ? null : AppGradients.limeGlow,
                          color: _controller.text.trim().isEmpty ? AppColors.border : null,
                          boxShadow: _controller.text.trim().isEmpty ? [] : AppShadows.glow(AppColors.lime),
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: _controller.text.trim().isEmpty ? AppColors.textMuted : Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.purpleGlow,
                boxShadow: AppShadows.glow(AppColors.purple),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ask me anything',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'I can answer questions from your uploaded documents.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return GestureDetector(
                  onTap: () => _ask(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(s, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime),
            ),
            SizedBox(width: 10),
            Text('Thinking…', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser, {bool isError = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isError ? null : AppGradients.purpleGlow,
                color: isError ? Colors.red.shade900 : null,
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                gradient: isUser ? AppGradients.purpleGlow : null,
                color: isUser ? null : (isError ? Colors.red.shade900.withOpacity(0.25) : AppColors.cardDark),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : (isError ? Colors.redAccent : AppColors.textPrimary),
                  height: 1.4,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}