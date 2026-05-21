import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with TickerProviderStateMixin {
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  late AnimationController _dotCtrl;
  late AnimationController _avatarCtrl;
  late AnimationController _micCtrl;

  // Voice
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening     = false;
  String _voiceText     = '';

  static const _suggestions = [
    ('🌊', 'Flood safety tips'),
    ('🏔️', 'Earthquake guide'),
    ('🩸', 'How to stop bleeding'),
    ('🔥', 'Fire escape plan'),
    ('🏥', 'Find nearest hospital'),
    ('🚨', 'Call for help'),
    ('🌡️', 'Heat stroke signs'),
    ('⛈️', 'Storm shelter guide'),
  ];

  @override
  void initState() {
    super.initState();
    _dotCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _avatarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _micCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') setState(() => _isListening = false); },
    );
    setState(() {});
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _dotCtrl.dispose();
    _avatarCtrl.dispose();
    _micCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _textCtrl.clear();
    setState(() => _voiceText = '');
    context.read<ChatProvider>().sendMessage(text.trim());
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleVoice() async {
    if (!_speechAvailable) return;
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_voiceText.isNotEmpty) _send(_voiceText);
    } else {
      setState(() { _isListening = true; _voiceText = ''; });
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceText = result.recognizedWords;
            if (result.finalResult && _voiceText.isNotEmpty) {
              _isListening = false;
              _send(_voiceText);
            }
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          localeId: 'en_US',
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            _buildHeader(chat),
            Expanded(child: _buildMessages(chat)),
            if (_isListening) _buildVoiceIndicator(),
            if (!chat.isTyping) _buildSuggestions(),
            _buildInputBar(chat),
          ]),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: AppColors.borderPrimary)),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.bgCard.withOpacity(0.8), AppColors.bgPrimary.withOpacity(0.6)],
        ),
      ),
      child: Row(children: [
        // Animated AI Avatar
        AnimatedBuilder(
          animation: _avatarCtrl,
          builder: (ctx, _) => Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [AppColors.aiPurple, AppColors.cyanPrimary],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.aiPurple.withOpacity(0.3 + 0.3 * _avatarCtrl.value),
                  blurRadius: 14 + 8 * _avatarCtrl.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AEGIS Assistant',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          Row(children: [
            Container(width: 6, height: 6,
              decoration: const BoxDecoration(color: AppColors.safeGreen, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            const Expanded(
              child: Text('Powered by Gemini · Always Ready',
                  style: TextStyle(color: AppColors.safeGreen, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ])),
        const SizedBox(width: 12),
        // Clear button
        GestureDetector(
          onTap: () {
            context.read<ChatProvider>().clearMessages();
            setState(() { _voiceText = ''; _isListening = false; });
          },
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 16),
          ),
        ),
      ]),
    ).animate().fadeIn();
  }

  // ── Messages ─────────────────────────────────────────────────────────────
  Widget _buildMessages(ChatProvider chat) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: chat.messages.length + (chat.isTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (chat.isTyping && i == chat.messages.length) return _typingBubble();
        final msg = chat.messages[i];
        return _MessageBubble(message: msg, index: i);
      },
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.aiPurple.withOpacity(0.08), AppColors.bgCard],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4), topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: AppColors.aiPurple.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.smart_toy_rounded, color: AppColors.aiPurple, size: 14),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _dotCtrl,
            builder: (ctx, _) => Row(mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = ((_dotCtrl.value * 3) - i).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6, height: 6 + 4 * phase,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: AppColors.aiPurple.withOpacity(0.4 + 0.6 * phase),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Thinking...', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  // ── Voice Indicator ───────────────────────────────────────────────────────
  Widget _buildVoiceIndicator() {
    return AnimatedBuilder(
      animation: _micCtrl,
      builder: (ctx, _) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.dangerRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dangerRed.withOpacity(0.3 + 0.2 * _micCtrl.value)),
          boxShadow: [BoxShadow(color: AppColors.dangerRed.withOpacity(0.1 * _micCtrl.value), blurRadius: 16)],
        ),
        child: Row(children: [
          // Animated microphone
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.dangerRed.withOpacity(0.15 + 0.1 * _micCtrl.value),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.dangerRed.withOpacity(0.3 * _micCtrl.value), blurRadius: 10)],
            ),
            child: const Icon(Icons.mic_rounded, color: AppColors.dangerRed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Listening...', style: TextStyle(color: AppColors.dangerRed, fontSize: 12, fontWeight: FontWeight.w700)),
            if (_voiceText.isNotEmpty)
              Text(_voiceText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)
            else
              const Text('Speak now — say your emergency question', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ])),
          // Waveform bars
          Row(children: List.generate(5, (i) {
            final h = 8.0 + 16 * math.sin(_micCtrl.value * math.pi * 2 + i * 0.8).abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3, height: h,
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withOpacity(0.6 + 0.4 * _micCtrl.value),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          })),
        ]),
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  // ── Suggestions ───────────────────────────────────────────────────────────
  Widget _buildSuggestions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Text('Quick Emergency Prompts',
            style: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ),
      SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _suggestions.length,
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final (emoji, label) = _suggestions[i];
            return GestureDetector(
              onTap: () => _send(label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.aiPurple.withOpacity(0.2)),
                  gradient: LinearGradient(
                    colors: [AppColors.aiPurple.withOpacity(0.06), AppColors.bgCard],
                  ),
                ),
                child: Center(child: Text('$emoji $label',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500))),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 6),
    ]);
  }

  // ── Input Bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar(ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        border: const Border(top: BorderSide(color: AppColors.borderPrimary)),
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppColors.bgPrimary.withOpacity(0.8), AppColors.bgPrimary],
        ),
      ),
      child: Row(children: [
        // Mic button
        GestureDetector(
          onTap: _speechAvailable ? _toggleVoice : null,
          child: AnimatedBuilder(
            animation: _micCtrl,
            builder: (ctx, _) => Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _isListening
                    ? AppColors.dangerRed.withOpacity(0.15 + 0.1 * _micCtrl.value)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: _isListening
                      ? AppColors.dangerRed.withOpacity(0.5)
                      : AppColors.borderPrimary,
                ),
                boxShadow: _isListening
                    ? [BoxShadow(color: AppColors.dangerRed.withOpacity(0.2 * _micCtrl.value), blurRadius: 12)]
                    : [],
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening ? AppColors.dangerRed : AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Text field
        Expanded(
          child: TextField(
            controller: _textCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            onSubmitted: _send,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: _isListening ? 'Listening...' : 'Ask AEGIS anything...',
              hintStyle: TextStyle(
                color: _isListening ? AppColors.dangerRed.withOpacity(0.6) : AppColors.textMuted,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.bgCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderPrimary)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderPrimary)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.aiPurple)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Send button
        GestureDetector(
          onTap: () => _send(_textCtrl.text),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.aiPurple, AppColors.cyanPrimary]),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: AppColors.aiPurple.withOpacity(0.4), blurRadius: 10)],
            ),
            child: chat.isTyping
                ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 19),
          ),
        ),
      ]),
    );
  }
}

// ── Message Bubble ─────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;
  const _MessageBubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final diff   = DateTime.now().difference(message.timestamp);
    final timeStr = diff.inMinutes < 1 ? 'just now'
        : diff.inMinutes < 60 ? '${diff.inMinutes}m ago'
        : '${diff.inHours}h ago';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 4,
              right: isUser ? 4 : 0,
              bottom: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: isUser
                  ? [
                      Text(timeStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      const SizedBox(width: 6),
                      const Text('You', style: TextStyle(color: AppColors.cyanPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]
                  : [
                      const Icon(Icons.smart_toy_rounded, color: AppColors.aiPurple, size: 12),
                      const SizedBox(width: 4),
                      const Text('AEGIS', style: TextStyle(color: AppColors.aiPurple, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Text(timeStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
            ),
          ),
          // Bubble
          Container(
            margin: EdgeInsets.only(
              left: isUser ? 60 : 0,
              right: isUser ? 0 : 60,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [AppColors.aiPurple.withOpacity(0.08), AppColors.bgCard],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser ? null : Border.all(color: AppColors.aiPurple.withOpacity(0.15)),
              boxShadow: isUser
                  ? [BoxShadow(color: const Color(0xFF0072FF).withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: _buildMessageContent(message.text, isUser),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 30))
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.15, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildMessageContent(String text, bool isUser) {
    // Simple markdown-lite parser: bold (**text**), bullets (- item)
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 4));
        continue;
      }

      // Bullet point
      if (line.startsWith('- ') || line.startsWith('• ') || line.startsWith('* ')) {
        final content = line.substring(2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('• ', style: TextStyle(
              color: isUser ? Colors.white.withOpacity(0.8) : AppColors.cyanPrimary,
              fontSize: 13, fontWeight: FontWeight.w700,
            )),
            Expanded(child: _inlineText(content, isUser)),
          ]),
        ));
      }
      // Numbered list
      else if (RegExp(r'^\d+[\.\)]\s').hasMatch(line)) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${line.substring(0, line.indexOf(' '))} ',
              style: TextStyle(
                color: isUser ? Colors.white.withOpacity(0.8) : AppColors.aiPurple,
                fontSize: 13, fontWeight: FontWeight.w700,
              )),
            Expanded(child: _inlineText(line.substring(line.indexOf(' ') + 1), isUser)),
          ]),
        ));
      }
      // Header (emoji or ** at start)
      else if (line.startsWith('**') && line.endsWith('**')) {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: i > 0 ? 6 : 0, bottom: 2),
          child: Text(line.replaceAll('**', ''),
            style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
        ));
      }
      else {
        widgets.add(_inlineText(line, isUser));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _inlineText(String text, bool isUser) {
    // Handle inline bold: **text**
    final parts = text.split('**');
    if (parts.length == 1) {
      return Text(text, style: TextStyle(
        color: isUser ? Colors.white : AppColors.textSecondary,
        fontSize: 13, height: 1.5,
      ));
    }
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          color: isUser ? Colors.white : (i.isOdd ? AppColors.textPrimary : AppColors.textSecondary),
          fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400,
          fontSize: 13, height: 1.5,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
