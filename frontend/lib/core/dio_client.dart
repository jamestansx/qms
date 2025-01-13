import 'package:dio/dio.dart';
import 'package:qms/main.dart';

abstract class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));
  }
}
