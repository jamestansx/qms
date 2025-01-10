import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qms/appointment/bloc/appointment_bloc.dart';
import 'package:qms/appointment/services/appointment.dart';
import 'package:qms/appointment/view/appointment_list_page.dart';
import 'package:qms/authentication/bloc/auth_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    final user = BlocProvider.of<AuthBloc>(context).state.patient!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Welcome back, ${context.read<AuthBloc>().state.patient?.username}"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountEmail: Text("${user.firstName} ${user.lastName}"),
              accountName: Text(user.username),
              currentAccountPicture: CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(
              leading: Icon(Icons.calendar_view_month),
              title: Text("Appointments"),
              onTap: () {
                Navigator.push(context, AppointmentListPage.route());
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.lock_open),
              title: Text("Logout"),
              onTap: () {
                context.read<AuthBloc>().add(LogoutUser());
              },
            ),
          ],
        ),
      ),
      body: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientId = context.read<AuthBloc>().state.patient!.id;
    return BlocProvider(
      create: (_) => AppointmentBloc(appointmentRepo: AppointmentRepo())
        ..add(AppointmentsFetched(patientId: patientId)),
      child: const AppointmentList(),
    );
  }
}
