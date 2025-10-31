import 'package:dio/dio.dart';

abstract class IApiClient {
  Future<Response> post(String path, {dynamic data});
  String get baseUrl; // 取用 BaseOptions.baseUrl（可選）
}