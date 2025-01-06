import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qms_staff/appointment/model/appointment.dart';
import 'package:qms_staff/appointment/model/patient.dart';
import 'package:qms_staff/core/dio_client.dart';

class AppointmentRepo extends DioClient {
  Future<Appointment> book(
    int patientId,
    DateTime scheduledAtUtc,
  ) async {
    try {
      Response response = await dio.post("/appointments/book", data: {
        "patient_id": patientId,
        "scheduled_at_utc": scheduledAtUtc.toUtc().toIso8601String(),
      });

      return Appointment.fromJson(response.data);
    } catch (e, stackTrace) {
      debugPrint("failed to book appointment:\n$e\n$stackTrace");
      rethrow;
    }
  }

  Future<List<Patient>> fetchPatients(String filter) async {
    try {
      Response response = await dio.get("/patients/list", queryParameters: {
        "name": filter,
      });

      List<Patient> list = [];
      for (var patient in response.data) {
        list.add(Patient.fromJson(patient));
      }
      return list;
    } catch (e, stackTrace) {
      debugPrint("failed to book appointment:\n$e\n$stackTrace");
      rethrow;
    }
  }
}
