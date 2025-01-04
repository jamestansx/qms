import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qms_staff/dashboard/bloc/wearable_bloc.dart';
import 'package:qms_staff/dashboard/services/wearables_repo.dart';
import 'package:real_time_chart/real_time_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? location;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WearableBloc, WearableState>(
      builder: (context, state) {
        if (state.streamData != null) {
          if (state.streamData!.topic == "accelerometer/fall" &&
              state.streamData!.deviceName == state.selectedItem?.deviceName) {
            setState(() {
              location = state.streamData!.data;
            });
          }
          return SizedBox(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 0.8,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: RealTimeGraph(
                        stream: RepositoryProvider.of<WearablesRepo>(context)
                            .stream
                            .asBroadcastStream()
                            .where((event) => event.topic == "heartRate/BPM")
                            .where((event) =>
                                event.deviceName ==
                                state.selectedItem?.deviceName)
                            .map((event) => double.parse(event.data)),
                      ),
                    ),
                  ),
                  if (location != null)
                    Card(
                      child: InkWell(
                        onLongPress: () {
                          setState(() {
                            location = null;
                          });
                        },
                        child: SizedBox(
                          child: Column(
                            children: [
                              const Text("Fall location: "),
                              Text(location!),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
