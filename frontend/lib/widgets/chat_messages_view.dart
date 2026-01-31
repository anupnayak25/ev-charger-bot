import 'package:flutter/material.dart';

import '../models/chat_models.dart';
import 'chat_bubble.dart';
import 'typing_bubble.dart';

class ChatMessagesView extends StatelessWidget {
  const ChatMessagesView({
    super.key,
    required this.turns,
    required this.isSending,
    required this.scrollController,
  });

  final List<ChatTurn> turns;
  final bool isSending;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = <_UiMessage>[];
    for (final t in turns) {
      items.add(_UiMessage(isUser: true, text: t.user));
      if (t.assistant != null && t.assistant!.trim().isNotEmpty) {
        items.add(_UiMessage(isUser: false, text: t.assistant!.trim()));
      }
    }

    final showTyping =
        isSending && turns.isNotEmpty && turns.last.assistant == null;
    if (showTyping) {
      items.add(const _UiMessage.typing());
    }

    if (items.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final m = items[index];
        if (m.isTyping) return const TypingBubble();
        return ChatBubble(isUser: m.isUser, text: m.text!);
      },
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
