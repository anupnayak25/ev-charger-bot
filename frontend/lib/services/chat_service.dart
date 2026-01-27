import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/chat_models.dart';

class BackendClient {
  BackendClient({required this.baseUrl, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  Uri _uri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Future<ChatResponse> chat({
    required List<ChatTurn> turns,
    String? summary,
    String? systemPrompt,
  }) async {
    if (turns.isEmpty) {
      throw ArgumentError('turns must not be empty');
    }

    final res = await _http.post(
      _uri('/api/chat'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: jsonEncode({
        'turns': turns.map((t) => t.toJson()).toList(),
        if (summary != null && summary.trim().isNotEmpty)
          'summary': summary.trim(),
        if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
          'system_prompt': systemPrompt.trim(),
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException(
        'Chat failed (${res.statusCode}): ${res.body}',
        uri: _uri('/api/chat'),
      );
    }

    return ChatResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<VoiceResponse> voiceAsk({
    required String audioFilePath,
    String? summary,
    String? systemPrompt,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/api/voice/ask'));

    if (summary != null && summary.trim().isNotEmpty) {
      req.fields['summary'] = summary.trim();
    }
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      req.fields['system_prompt'] = systemPrompt.trim();
    }

    req.files.add(await http.MultipartFile.fromPath('audio', audioFilePath));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw HttpException(
        'Voice ask failed (${streamed.statusCode}): $body',
        uri: _uri('/api/voice/ask'),
      );
    }

    return VoiceResponse.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }
}
