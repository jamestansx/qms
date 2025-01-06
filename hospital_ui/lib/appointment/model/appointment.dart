import 'package:equatable/equatable.dart';

class Appointment extends Equatable {
  final int id;
  final String uuid;
  final int patientId;
  final DateTime scheduledAtUtc;

  const Appointment({
    required this.id,
    required this.uuid,
    required this.patientId,
    required this.scheduledAtUtc,
  });

  factory Appointment.fromJson(var json) {
    return Appointment(
      scheduledAtUtc: DateTime.parse(json["scheduled_at_utc"]),
      patientId: json["patient_id"],
      uuid: json["uuid"],
      id: json["id"],
    );
  }

  @override
  List<Object?> get props => [patientId, scheduledAtUtc];
}
