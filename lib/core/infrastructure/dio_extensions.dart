// Dart imports:
import 'dart:io';

// Package imports:
import 'package:dio/dio.dart';

extension DioErrorX on DioError {
  bool get isNoConnectionError {
    return type == DioErrorType.other && error is SocketException;
  }
}
