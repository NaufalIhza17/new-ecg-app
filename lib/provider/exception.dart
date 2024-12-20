import 'package:http/http.dart';

class ResumableUploadException implements Exception {
  final String message;
  final Response? response;
  ResumableUploadException(this.message, {this.response});

  @override
  String toString() => 'ResumableUploadException: $message';
}