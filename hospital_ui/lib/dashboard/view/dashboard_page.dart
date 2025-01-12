import 'dart:async';

import 'package:flutter/gestures.dart';
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

  Widget buildChart(List<TimeSeries> data) {
    return Chart(
      data: data,
      variables: {
        "time": Variable(
          accessor: (TimeSeries datum) => datum.dt,
          scale: TimeScale(
            formatter: (t) => DateFormat.Hms().format(t),
          ),
        ),
        "heartrate": Variable(
          accessor: (TimeSeries datum) => datum.value,
        ),
      },
      marks: [
        LineMark(
          shape: ShapeEncode(value: BasicLineShape()),
          size: SizeEncode(value: 1),
          selected: {
            "touchMove": {1},
          },
        ),
      ],
      coord: RectCoord(color: const Color(0xffdddddd)),
      axes: [
        Defaults.horizontalAxis
          ..label = LabelStyle(
              textStyle: const TextStyle(
            fontSize: 12,
          )),
        Defaults.verticalAxis
          ..label = LabelStyle(
              textStyle: const TextStyle(
            fontSize: 12,
          )),
      ],
      selections: {
        'tooltipMouse': PointSelection(on: {
          GestureType.hover,
        }, devices: {
          PointerDeviceKind.mouse
        }, dim: Dim.x),
        'tooltipTouch': PointSelection(on: {
          GestureType.scaleUpdate,
          GestureType.tapDown,
          GestureType.longPressMoveUpdate
        }, devices: {
          PointerDeviceKind.touch
        }, dim: Dim.x),
      },
      tooltip: TooltipGuide(
        followPointer: [true, true],
        align: Alignment.topLeft,
      ),
      crosshair: CrosshairGuide(
        followPointer: [false, true],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wearables =
        context.select((WearableBloc bloc) => bloc.state.wearables);

    return SizedBox(
      child: SingleChildScrollView(
        child: Column(
          children: [
            BlocBuilder<WearableBloc, WearableState>(builder: (context, state) {
              if (state.streamData != null &&
                  state.streamData!.topic == "accelerometer/fall" &&
                  state.wearables.any(
                    (e) => e.deviceName == state.streamData!.deviceName,
                  )) {
                location = state.streamData!.data;
              }

              if (state.isAlertDismissed ?? false) {
                location = null;
              }
              return Column(children: [
                if (location != null)
                  const Text(
                    "Fall location: ",
                    style: TextStyle(
                      fontSize: 20,
                      backgroundColor: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (location != null)
                  Text(
                    location!,
                    style: const TextStyle(
                      fontSize: 20,
                      backgroundColor: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (location != null) const SizedBox(height: 20),
              ]);
            }),
            const Text(
              "Heart Rate Monitoring",
              style: TextStyle(fontSize: 20),
            ),
            StreamBuilder(
              stream: RepositoryProvider.of<WearablesRepo>(context)
                  .controller
                  .stream
                  .where((event) => event.topic == "heartRate/BPM")
                  .where((event) =>
                      wearables.any((e) => e.deviceName == event.deviceName))
                  .map((ev) => TimeSeries(
                      dt: DateTime.now(), value: int.parse(ev.data))),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  data.add(snapshot.data!);
                }
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: MediaQuery.of(context).size.width * 0.55,
                  height: MediaQuery.of(context).size.height - 100,
                  child: buildChart(data),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
