import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.backendUrl});

  final String backendUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();

  String? _systemPrompt;
  String? _summary;

  final List<ChatTurn> _turns = [];

  bool _isSending = false;
  bool _isRecording = false;

  BackendClient get _client => BackendClient(baseUrl: widget.backendUrl);

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendText() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _isSending || _isRecording) return;

    setState(() {
      _isSending = true;
      _turns.add(ChatTurn(user: text));
      _composerController.clear();
    });
    _scrollToBottomSoon();

    try {
      final res = await _client.chat(
        turns: List.of(_turns),
        summary: _summary,
        systemPrompt: _systemPrompt,
      );

      if (!mounted) return;
      setState(() {
        final last = _turns.removeLast();
        _turns.add(ChatTurn(user: last.user, assistant: res.reply));
      });
      _scrollToBottomSoon();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _turns.removeLast();
      });
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<String> _newRecordingPath() async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}${Platform.pathSeparator}voice_$ts.m4a';
  }

  Future<void> _toggleRecording() async {
    if (_isSending) return;

    if (_isRecording) {
      final path = await _recorder.stop();
      if (!mounted) return;

      setState(() => _isRecording = false);

      if (path == null || path.isEmpty) {
        _showError('Recording failed (no audio file).');
        return;
      }

      await _sendVoice(path);
      return;
    }

    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      _showError('Microphone permission is required to record audio.');
      return;
    }

    final path = await _newRecordingPath();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    if (!mounted) return;
    setState(() => _isRecording = true);
  }

  Future<void> _sendVoice(String audioPath) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _turns.add(ChatTurn(user: '🎤 Voice message…'));
    });
    _scrollToBottomSoon();

    try {
      final res = await _client.voiceAsk(
        audioFilePath: audioPath,
        summary: _summary,
        systemPrompt: _systemPrompt,
      );

      if (!mounted) return;
      setState(() {
        _turns.removeLast();
        _turns.add(ChatTurn(user: res.transcript, assistant: res.reply));
      });
      _scrollToBottomSoon();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _turns.removeLast();
      });
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);

      try {
        final f = File(audioPath);
        if (await f.exists()) await f.delete();
      } catch (_) {
        // ignore cleanup failures
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = <_UiMessage>[];
    for (final t in _turns) {
      items.add(_UiMessage(isUser: true, text: t.user));
      if (t.assistant != null && t.assistant!.trim().isNotEmpty) {
        items.add(_UiMessage(isUser: false, text: t.assistant!.trim()));
      }
    }

    final showTyping =
        _isSending && _turns.isNotEmpty && _turns.last.assistant == null;
    if (showTyping) {
      items.add(const _UiMessage.typing());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('EV Charger Bot')),
      body: Column(
        children: [
          if (widget.backendUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  if (_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Recording…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Ask anything about EV charging issues.\n\nType a message or press the mic to talk.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final m = items[index];
                      if (m.isTyping) return const _TypingBubble();
                      return ChatBubble(isUser: m.isUser, text: m.text!);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composerController,
                      enabled: !_isRecording,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (_isRecording) return;
                        _sendText();
                      },
                      decoration: InputDecoration(
                        hintText: _isRecording ? 'Recording…' : 'Message…',
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintStyle: _isRecording
                            ? theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              )
                            : null,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _composerController,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;

                      late final Widget button;
                      if (_isRecording) {
                        button = IconButton.filledTonal(
                          key: const ValueKey('stop'),
                          tooltip: 'Stop recording',
                          onPressed: _toggleRecording,
                          icon: const Icon(Icons.stop),
                        );
                      } else if (hasText) {
                        button = IconButton.filledTonal(
                          key: const ValueKey('send'),
                          tooltip: 'Send',
                          onPressed: _isSending ? null : _sendText,
                          icon: const Icon(Icons.send),
                        );
                      } else {
                        button = IconButton.filledTonal(
                          key: const ValueKey('mic'),
                          tooltip: 'Record voice',
                          onPressed: _isSending ? null : _toggleRecording,
                          icon: const Icon(Icons.mic),
                        );
                      }

                      return SizedBox(
                        width: 48,
                        height: 48,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            final curved = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            );
                            return FadeTransition(
                              opacity: curved,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.92,
                                  end: 1.0,
                                ).animate(curved),
                                child: child,
                              ),
                            );
                          },
                          child: button,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UiMessage {
  const _UiMessage({required this.isUser, required this.text})
    : isTyping = false;

  const _UiMessage.typing() : isUser = false, text = null, isTyping = true;

  final bool isUser;
  final String? text;
  final bool isTyping;
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceContainerHighest;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const _TypingDots(),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (t * 2 * math.pi) + (i * 0.9);
            final wave = (math.sin(phase) + 1) / 2; // 0..1
            final opacity = 0.25 + (wave * 0.75);
            final scale = 0.85 + (wave * 0.25);
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
