import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class _ChatMessage {
  final int id;
  final String text;
  final bool isUser;
  final bool isError;
  _ChatMessage(this.id, this.text, this.isUser, {this.isError = false});
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

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;
  bool _listening = false;
  bool _speakEnabled = true;
  int? _speakingId;

  static const _suggestions = [
    'Summarize this document',
    'List key points',
    'Explain chapter 1',
    'Give me 5 quiz questions',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (_) => setState(() => _listening = false),
    );
    setState(() {});
  }

  void _initTts() {
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() => setState(() => _speakingId = null));
    _tts.setCancelHandler(() => setState(() => _speakingId = null));
    _tts.setErrorHandler((_) => setState(() => _speakingId = null));
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is needed for voice input.')),
      );
      await _initSpeech();
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          setState(() => _listening = false);
          if (text.trim().isNotEmpty) _ask(text);
        }
      },
    );
  }

  Future<void> _speak(String text, int id) async {
    await _tts.stop();
    setState(() => _speakingId = id);
    await _tts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    setState(() => _speakingId = null);
  }

  Future<void> _ask([String? preset]) async {
    final question = (preset ?? _controller.text).trim();
    if (question.isEmpty) return;

    final userId = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _messages.add(_ChatMessage(userId, question, true));
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final res = await ApiService.queryDocuments(question);
      final answer = res['answer'] ?? 'No answer returned.';
      final aiId = userId + 1;
      setState(() {
        _messages.add(_ChatMessage(aiId, answer, false));
      });
      if (_speakEnabled) _speak(answer, aiId);
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(userId + 1, 'Something went wrong answering that.', false, isError: true));
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
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navClearance = 108.0;

    return Stack(
      children: [
        Positioned(top: -50, right: -30, child: _blob(AppColors.purple.withOpacity(0.2), 160)),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_speakEnabled) _stopSpeaking();
                      setState(() => _speakEnabled = !_speakEnabled);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _speakEnabled ? AppColors.lime.withOpacity(0.5) : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _speakEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            size: 16,
                            color: _speakEnabled ? AppColors.lime : AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) return _buildThinkingBubble();
                        final m = _messages[index];
                        return _buildBubble(m);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, navClearance),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _listening
                            ? const LinearGradient(colors: [Color(0xFFFF6F91), Color(0xFFFF4D6D)])
                            : null,
                        color: _listening ? null : AppColors.cardDark,
                        border: _listening ? null : Border.all(color: AppColors.border),
                        boxShadow: _listening ? AppShadows.glow(const Color(0xFFFF6F91)) : [],
                      ),
                      child: Icon(
                        _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _listening ? Colors.white : AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              decoration: InputDecoration(
                                hintText: _listening ? 'Listening…' : 'Ask about your notes…',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            const Text('Ask me anything',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'Type, or tap the mic to speak your question.',
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
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime)),
            SizedBox(width: 10),
            Text('Thinking…', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage m) {
    final isUser = m.isUser;
    final isError = m.isError;
    final isSpeaking = _speakingId == m.id;

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
              child: Icon(isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : (isError ? Colors.redAccent : AppColors.textPrimary),
                      height: 1.4,
                      fontSize: 14.5,
                    ),
                  ),
                  if (!isUser && !isError) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => isSpeaking ? _stopSpeaking() : _speak(m.text, m.id),
                      child: Icon(
                        isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                        size: 16,
                        color: isSpeaking ? AppColors.lime : AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
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
        child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      ),
    );
  }
}