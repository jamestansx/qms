import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qms/appointment/bloc/appointment_bloc.dart';
import 'package:qms/appointment/services/appointment.dart';
import 'package:qms/appointment/view/appointment_qr_page.dart';
import 'package:qms/authentication/bloc/auth_bloc.dart';

class AppointmentListPage extends StatelessWidget {
  const AppointmentListPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const AppointmentListPage());
  }

  @override
  Widget build(BuildContext context) {
    final patientId = context.read<AuthBloc>().state.patient!.id;
    return Scaffold(
      appBar: AppBar(),
      body: BlocProvider(
        create: (_) => AppointmentBloc(appointmentRepo: AppointmentRepo())
          ..add(AppointmentsFetched(patientId: patientId)),
        child: const AppointmentList(),
      ),
    );
  }
}

class AppointmentList extends StatelessWidget {
  const AppointmentList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        switch (state.status) {
          case AppointmentStatus.initial:
            return const Center(child: CircularProgressIndicator());
          case AppointmentStatus.failure:
            return Center(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(child: Text("Failed to fetch appointments")),
                ),
              ),
            );
          case AppointmentStatus.success:
            return RefreshIndicator(
              onRefresh: () async {
                Future block = context.read<AppointmentBloc>().stream.first;
                final int patientId =
                    context.read<AuthBloc>().state.patient!.id;
                context
                    .read<AppointmentBloc>()
                    .add(AppointmentsFetched(patientId: patientId));
                await block;
              },
              child: state.appointments.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: Center(child: Text("No appointments found")),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.appointments.length,
                      itemBuilder: (context, idx) {
                        final appointment = state.appointments[idx];
                        return Material(
                          child: ListTile(
                            leading: Text(
                              "ID: ${appointment.id}",
                              style: TextStyle(
                                fontSize: 16.0,
                                wordSpacing: 0.5,
                              ),
                            ),
                            title: Text("Scheduled at:"),
                            subtitle: Text(
                              DateFormat().format(
                                appointment.scheduledAtUtc.toLocal(),
                              ),
                              style: TextStyle(
                                fontSize: 16.0,
                                wordSpacing: 0.5,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                AppointmentQrPage.route(appointment.uuid),
                              );
                            },
                            dense: true,
                          ),
                        );
                      },
                    ),
            );
        }
      },
    );
  }
}
