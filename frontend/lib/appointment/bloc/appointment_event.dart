part of "appointment_bloc.dart";

sealed class AppointmentEvent {
  const AppointmentEvent();
}

final class AppointmentsFetched extends AppointmentEvent {
  final int patientId;

  AppointmentsFetched({required this.patientId});
}
