import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qms_staff/dashboard/bloc/wearable_bloc.dart';

class WearablesList extends StatefulWidget {
  const WearablesList({super.key});

  @override
  State<WearablesList> createState() => _WearablesListState();
}

class _WearablesListState extends State<WearablesList> {
  List<String> alertDevice = [];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WearableBloc, WearableState>(
      listener: (context, state) {
        if (state.streamData != null &&
            state.streamData!.topic == "accelerometer/fall") {
          if (state.streamData!.deviceName == state.selectedItem?.deviceName) {
            alertDevice.add(state.streamData!.deviceName);
          }
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case WearableStatus.initial:
            return const Center(child: CircularProgressIndicator());
          case WearableStatus.failure:
            return const Center(child: Text("YOU FUCKED UP"));
          case WearableStatus.success:
            return ListView.builder(
              itemCount: state.wearables.length,
              itemBuilder: (context, idx) {
                final item = state.wearables[idx];

                return Material(
                  child: ListTile(
                    leading: alertDevice.contains(item.deviceName)
                        ? const Icon(Icons.play_circle_fill)
                        : null,
                    title: Text(item.deviceName),
                    dense: true,
                    subtitle: Text(item.uuid),
                    onTap: () {
                      alertDevice.remove(item.deviceName);
                      context.read<WearableBloc>().add(
                            SelectWearable(wearable: item),
                          );
                    },
                  ),
                );
              },
            );
        }
      },
    );
  }
}
