import 'package:equatable/equatable.dart';

class Appointment extends Equatable {
  final int id;
  final int patientId;
  final String uuid;
  final DateTime scheduledAtUtc;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.uuid,
    required this.scheduledAtUtc,
  });

  factory Appointment.fromJson(var json) {
    return Appointment(
      id: json["id"],
      uuid: json["uuid"],
      patientId: json["patient_id"],
      scheduledAtUtc: DateTime.parse(json["scheduled_at_utc"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "uuid": uuid,
      "patient_id": patientId,
      "scheduled_at_utc": scheduledAtUtc.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, uuid, patientId];
}
