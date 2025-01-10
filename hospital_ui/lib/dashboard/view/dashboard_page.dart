import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';
import 'package:qms_staff/dashboard/bloc/wearable_bloc.dart';
import 'package:qms_staff/dashboard/model/stream_data.dart';
import 'package:qms_staff/dashboard/services/wearables_repo.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.controller,
  });

  final StreamController<StreamData> controller;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class TimeSeries {
  final DateTime dt;
  final int value;

  TimeSeries({required this.dt, required this.value});
}

class _DashboardPageState extends State<DashboardPage> {
  String? location;
  List<TimeSeries> data = [];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WearableBloc, WearableState>(
      builder: (context, state) {
        if (state.streamData != null) {
          if (state.streamData!.topic == "accelerometer/fall" &&
              state.wearables.any(
                (e) => e.deviceName == state.streamData!.deviceName,
              )) {
            location = state.streamData!.data;
          }
          return SizedBox(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    "Heart Rate Monitoring",
                    style: TextStyle(fontSize: 20),
                  ),
                  StreamBuilder(
                    stream: RepositoryProvider.of<WearablesRepo>(context)
                        .stream
                        .where((event) => event.topic == "heartRate/BPM")
                        .where((event) => state.wearables
                            .any((e) => e.deviceName == event.deviceName))
                        .map((ev) => TimeSeries(
                            dt: DateTime.now(), value: int.parse(ev.data))),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        data.add(snapshot.data!);
                      }
                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: MediaQuery.of(context).size.width * 0.55,
                        height: MediaQuery.of(context).size.height,
                        child: Chart(
                          data: data,
                          variables: {
                            "dt": Variable(
                              accessor: (TimeSeries datum) => datum.dt,
                              scale: TimeScale(
                                formatter: (t) => DateFormat.Hms().format(t),
                              ),
                            ),
                            "value": Variable(
                              accessor: (TimeSeries datum) => datum.value,
                            ),
                          },
                          marks: [
                            LineMark(
                              shape: ShapeEncode(
                                  value: BasicLineShape(dash: [5, 2])),
                              selected: {
                                "touchMove": {1},
                              },
                            ),
                          ],
                          coord: RectCoord(color: const Color(0xffdddddd)),
                          axes: [
                            Defaults.horizontalAxis,
                            Defaults.verticalAxis,
                          ],
                          selections: {
                            "touchMove": PointSelection(
                              on: {
                                GestureType.scaleUpdate,
                                GestureType.tapDown,
                                GestureType.longPressMoveUpdate,
                              },
                              dim: Dim.x,
                            ),
                          },
                        ),
                      );
                    },
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
