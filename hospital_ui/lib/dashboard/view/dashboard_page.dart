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
              state.streamData!.deviceName ==
                  state.wearables[state.selectedIdx].deviceName) {
            setState(() {
              location = state.streamData!.data;
            });
          }
          return SizedBox(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: RealTimeGraph(
                        stream: RepositoryProvider.of<WearablesRepo>(context)
                            .stream
                            .where((event) => event.topic == "heartRate/BPM")
                            .where((event) =>
                                event.deviceName ==
                                state.wearables[state.selectedIdx].deviceName)
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

        return const Expanded(
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
