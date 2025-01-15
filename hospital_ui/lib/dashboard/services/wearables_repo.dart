import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qms_staff/core/dio_client.dart';
import 'package:qms_staff/dashboard/model/stream_data.dart';
import 'package:qms_staff/dashboard/model/wearable.dart';

class WearablesRepo extends DioClient {
  final _controller = StreamController<StreamData>.broadcast(sync: true);

  StreamController<StreamData> get controller => _controller;

  void dispose() {
    _controller.close();
  }

  Future<void> monitor() async {
    final FetchClient cl = FetchClient(mode: RequestMode.cors);
    final res = await cl.send(
      http.Request(
        "GET",
        Uri.http("${DioClient.apiUrl}:8000", "/api/v1/wearables/monitor"),
      ),
    );

    final stream = res.stream
        .toStringStream()
        .where(
          (event) => event.isNotEmpty,
        )
        .map(
          (event) => StreamData.fromJson(
            jsonDecode(
              event.substring("data: ".length),
            ),
          ),
        );

    stream.listen((ev) => _controller.add(ev));
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

  Future<void> ackFall() async {
    try {
      await dio.get("/wearables/fallack");
    } catch (_) {
      rethrow;
    }
  }

  Future<String> register(String deviceName) async {
    try {
      Response response = await dio.post("/wearables/register", data: {
        "device_name": deviceName,
      });

      return response.data;
    } catch (_) {
      rethrow;
    }
  }
}
