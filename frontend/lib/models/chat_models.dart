class ChatTurn {
  ChatTurn({required this.user, this.assistant});

  final String user;
  final String? assistant;

  Map<String, dynamic> toJson() => {
    'user': user,
    if (assistant != null) 'assistant': assistant,
  };
}

class ChatResponse {
  ChatResponse({required this.reply});

  final String reply;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(reply: (json['reply'] as String?) ?? '');
  }
}

class VoiceResponse {
  VoiceResponse({required this.transcript, required this.reply});

  final String transcript;
  final String reply;

  factory VoiceResponse.fromJson(Map<String, dynamic> json) {
    return VoiceResponse(
      transcript: (json['transcript'] as String?) ?? '',
      reply: (json['reply'] as String?) ?? '',
    );
  }
}
