import 'package:dio/dio.dart';

abstract class DioClient {
  static const apiUrl = String.fromEnvironment(
    "BASEURL",
    defaultValue: "localhost",
  );
  static const baseUrl = "http://$apiUrl:8000/api/v1";
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));
  }
}
