import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qms/appointment/model/appointment.dart';
import 'package:qms/appointment/services/appointment.dart';

part "appointment_state.dart";
part "appointment_event.dart";

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  AppointmentBloc({
    required AppointmentRepo appointmentRepo,
  })  : _appointmentRepo = appointmentRepo,
        super(const AppointmentState()) {
    on<AppointmentsFetched>(_onFetch);
  }

  final AppointmentRepo _appointmentRepo;

  Future<void> _onFetch(
    AppointmentsFetched event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      final appointments = await _appointmentRepo.list(event.patientId);
      emit(
        state.copyWith(
          status: AppointmentStatus.success,
          appointments: appointments,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: AppointmentStatus.failure));
    }
  }
}
