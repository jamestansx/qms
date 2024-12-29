import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qms/core/dio_client.dart';
import 'package:qms/patient/model/patient.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, failure }

class AuthRepo extends DioClient {
  final _controller = StreamController<AuthStatus>();

  void dispose() => _controller.close();

  Future<Patient> login({
    required String username,
    required String password,
  }) async {
    try {
      Response response = await dio.post(
        "/patients/login",
        data: {"username": username, "password": password},
      );

      final Patient patient = Patient.fromJson(response.data);
      _controller.add(AuthStatus.authenticated);
      return patient;
    } catch (e, stackTrace) {
      debugPrint("Error on login\n $e\n $stackTrace");
      _controller.add(AuthStatus.failure);
      rethrow;
    }
  }

  Future<void> logout() async {
    _controller.add(AuthStatus.unauthenticated);
  }

  Future<Patient> register({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required DateTime dateOfBirth,
  }) async {
    try {
      Response response = await dio.post(
        "/patients/register",
        data: {
          "username": username,
          "firstName": firstName,
          "lastName": lastName,
          "password": password,
          "dateOfBirth": DateFormat("yyyy-MM-dd").format(dateOfBirth),
        },
      );

      final Patient patient = Patient.fromJson(response.data);
      _controller.add(AuthStatus.authenticated);
      return patient;
    } catch (e, stackTrace) {
      print("Error on login\n $e\n $stackTrace");
      _controller.add(AuthStatus.failure);
      rethrow;
    }
  }

  Stream<AuthStatus> get status async* {
    final prefs = SharedPreferencesAsync();
    final user = await prefs.getString("user");
    if (user != null) {
      yield AuthStatus.authenticated;
    } else {
      yield AuthStatus.unauthenticated;
    }
    yield* _controller.stream;
  }
}