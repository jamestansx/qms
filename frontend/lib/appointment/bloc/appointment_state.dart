part of "appointment_bloc.dart";

enum AppointmentStatus { initial, success, failure }

final class AppointmentState extends Equatable {
  const AppointmentState({
    this.status = AppointmentStatus.initial,
    this.appointments = const <Appointment>[],
    this.isLoading,
  });

  final AppointmentStatus status;
  final List<Appointment> appointments;
  final bool? isLoading;

  AppointmentState copyWith({
    AppointmentStatus? status,
    List<Appointment>? appointments,
    bool? isLoading,
  }) {
    return AppointmentState(
      status: status ?? this.status,
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [status, appointments, isLoading];
}
