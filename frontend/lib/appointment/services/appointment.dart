import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qms/appointment/model/appointment.dart';
import 'package:qms/core/dio_client.dart';

class AppointmentRepo extends DioClient {
  Future<List<Appointment>> list(int patientId) async {
    try {
      Response response = await dio.get("/appointments/$patientId");

      List<Appointment> appointments = [];
      for (Map<String, dynamic> appointment in response.data) {
        appointments.add(Appointment.fromJson(appointment));
      }
      return appointments;
    } catch (e, stackTrace) {
      debugPrint("Error on listing appointments\n$e\n$stackTrace");
      rethrow;
    }
  }
}
