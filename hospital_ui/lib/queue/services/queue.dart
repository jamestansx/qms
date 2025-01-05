import 'package:fetch_client/fetch_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:qms_staff/core/dio_client.dart';

class QueueRepo extends DioClient {
  Future<FetchResponse> webStatus() async {
    final FetchClient cl = FetchClient(mode: RequestMode.cors);
    return cl.send(
      Request(
        "GET",
        Uri.http("192.168.0.2:8000", "/api/v1/queues"),
      ),
    );
  }

  Future<void> nextQueue() async {
    try {
      await dio.get("/queues/next");
    } catch (e, stackTrace) {
      debugPrint("Nex queue failed with:\n$e\n$stackTrace");
      rethrow;
    }
  }

  Future<void> alertQueue() async {
    try {
      await dio.get("/queues/alert");
    } catch (e, stackTrace) {
      debugPrint("Nex queue failed with:\n$e\n$stackTrace");
      rethrow;
    }
  }
}
