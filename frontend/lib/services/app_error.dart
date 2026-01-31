import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

enum AppErrorCode { noInternet, serverError, timeout, badResponse, unknown }

class AppError {
  const AppError({required this.code, this.statusCode, this.details});

  final AppErrorCode code;
  final int? statusCode;
  final String? details;

  AppErrorDisplay toDisplay() {
    switch (code) {
      case AppErrorCode.noInternet:
        return const AppErrorDisplay(
          title: 'No internet',
          message:
              'No internet connection. Please check your network and try again.',
        );
      case AppErrorCode.serverError:
        return AppErrorDisplay(
          title: 'Server error',
          message: 'The server is not responding correctly. Please try again.',
        );
      case AppErrorCode.timeout:
        return const AppErrorDisplay(
          title: 'Request timed out',
          message: 'The request took too long. Please try again.',
        );
      case AppErrorCode.badResponse:
        return const AppErrorDisplay(
          title: 'Unexpected response',
          message: 'Received an unexpected response. Please try again.',
        );
      case AppErrorCode.unknown:
        return const AppErrorDisplay(
          title: 'Something went wrong',
          message: 'Please try again.',
        );
    }
  }
}

class AppErrorDisplay {
  const AppErrorDisplay({required this.title, required this.message});

  final String title;
  final String message;
}

AppError mapToAppError(Object error) {
  // Common network cases
  if (error is SocketException) {
    return const AppError(code: AppErrorCode.noInternet);
  }
  if (error is TimeoutException) {
    return const AppError(code: AppErrorCode.timeout);
  }

  // http package typically wraps socket errors in ClientException
  if (error is http.ClientException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('failed host lookup') || msg.contains('socketexception')) {
      return const AppError(code: AppErrorCode.noInternet);
    }
    return AppError(code: AppErrorCode.unknown, details: error.message);
  }

  // From BackendClient: HttpException with status embedded in message
  if (error is HttpException) {
    final status = _tryExtractStatusCode(error.message);
    if (status != null) {
      if (status >= 500) {
        return AppError(code: AppErrorCode.serverError, statusCode: status);
      }
      if (status == 408 || status == 429) {
        return AppError(code: AppErrorCode.timeout, statusCode: status);
      }
      return AppError(code: AppErrorCode.badResponse, statusCode: status);
    }
    return AppError(code: AppErrorCode.serverError, details: error.message);
  }

  return AppError(code: AppErrorCode.unknown, details: error.toString());
}

int? _tryExtractStatusCode(String message) {
  // Matches patterns like: "Chat failed (500): ..." or "Voice ask failed (422): ..."
  final m = RegExp(r'\((\d{3})\)').firstMatch(message);
  if (m == null) return null;
  return int.tryParse(m.group(1) ?? '');
}
