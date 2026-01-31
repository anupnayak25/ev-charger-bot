import 'package:flutter/material.dart';

class ChatComposerBar extends StatelessWidget {
  const ChatComposerBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.isRecording,
    required this.onSend,
    required this.onToggleRecording,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onToggleRecording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
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
                controller: controller,
                enabled: !isRecording,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (isRecording) return;
                  onSend();
                },
                decoration: InputDecoration(
                  hintText: isRecording ? 'Recording…' : 'Message…',
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintStyle: isRecording
                      ? theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;

                late final Widget button;
                if (isRecording) {
                  button = IconButton.filledTonal(
                    key: const ValueKey('stop'),
                    tooltip: 'Stop recording',
                    onPressed: onToggleRecording,
                    icon: const Icon(Icons.stop),
                  );
                } else if (hasText) {
                  button = IconButton.filledTonal(
                    key: const ValueKey('send'),
                    tooltip: 'Send',
                    onPressed: isSending ? null : onSend,
                    icon: const Icon(Icons.send),
                  );
                } else {
                  button = IconButton.filledTonal(
                    key: const ValueKey('mic'),
                    tooltip: 'Record voice',
                    onPressed: isSending ? null : onToggleRecording,
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
    );
  }
}
