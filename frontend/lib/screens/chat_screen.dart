import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/app_error.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_messages_view.dart';
import '../widgets/app_dialogs.dart';

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
  bool _isShowingErrorDialog = false;

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

    final pendingText = text;

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
      await _showErrorDialog(
        mapToAppError(e),
        onRetry: () {
          _composerController.text = pendingText;
          _composerController.selection = TextSelection.fromPosition(
            TextPosition(offset: _composerController.text.length),
          );
          _sendText();
        },
      );
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
        await _showMessageDialog(
          title: 'Recording failed',
          message: 'No audio file was created. Please try again.',
        );
        return;
      }

      await _sendVoice(path);
      return;
    }

    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      await _showMessageDialog(
        title: 'Permission required',
        message: 'Microphone permission is required to record audio.',
      );
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

      try {
        final f = File(audioPath);
        if (await f.exists()) await f.delete();
      } catch (_) {
        // ignore cleanup failures
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _turns.removeLast();
      });
      await _showErrorDialog(mapToAppError(e));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) async {
    if (_isShowingErrorDialog || !mounted) return;
    _isShowingErrorDialog = true;
    try {
      await AppDialogs.showMessage(context, title: title, message: message);
    } finally {
      _isShowingErrorDialog = false;
    }
  }

  Future<void> _showErrorDialog(AppError error, {VoidCallback? onRetry}) async {
    if (_isShowingErrorDialog || !mounted) return;
    _isShowingErrorDialog = true;
    try {
      await AppDialogs.showError(context, error: error, onRetry: onRetry);
    } finally {
      _isShowingErrorDialog = false;
    }
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
            child: ChatMessagesView(
              turns: _turns,
              isSending: _isSending,
              scrollController: _scrollController,
            ),
          ),
          ChatComposerBar(
            controller: _composerController,
            isSending: _isSending,
            isRecording: _isRecording,
            onSend: _sendText,
            onToggleRecording: _toggleRecording,
          ),
        ],
      ),
    );
  }
}
