import 'package:dio/dio.dart';

abstract class DioClient {
  static const apiUrl = "192.168.0.2";
  static const baseUrl = "http://$apiUrl:8000/api/v1";
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));
  }
}
