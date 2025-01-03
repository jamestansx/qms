import 'package:dio/dio.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qms_staff/core/dio_client.dart';
import 'package:qms_staff/dashboard/model/wearable.dart';

class WearablesRepo extends DioClient {
  Future<FetchResponse> monitor() async {
    final FetchClient cl = FetchClient(mode: RequestMode.cors);
    final res = await cl.send(
      http.Request(
        "GET",
        Uri.http("192.168.0.2:3000", "/api/v1/wearables/monitor"),
      ),
    );

    return res;
  }

  Future<List<Wearable>> fetchList() async {
    try {
      Response response = await dio.get("/wearables/list");

      List<Wearable> wearables = [];
      for (Map<String, dynamic> wearable in response.data) {
        wearables.add(Wearable.fromJson(wearable));
      }
      return wearables;
    } catch (e, stackTrace) {
      debugPrint("Error on listing wearables\n$e\n$stackTrace");
      rethrow;
    }
  }
}
