import 'package:dio/dio.dart';

abstract class DioClient {
  static const baseUrl = "http://192.168.0.2:3000/api/v1";
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));
  }
}
