import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qms_staff/dashboard/bloc/wearable_bloc.dart';
import 'package:qms_staff/dashboard/view/add_wearables_dialog.dart';

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
          if (state.streamData!.deviceName ==
              state.wearables[state.selectedIdx].deviceName) {
            alertDevice.add(state.streamData!.deviceName);
          }
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case WearableStatus.initial:
            return const Expanded(
              child: Center(child: CircularProgressIndicator()),
            );
          case WearableStatus.failure:
            return const Expanded(
              child: Center(child: Text("Connection Lost!")),
            );
          case WearableStatus.success:
            if (state.isAlertDismissed ?? false) {
              alertDevice.remove(state.alertDevice!);
            }
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.25,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        "Device List",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          wordSpacing: 0.5,
                        ),
                      ),
                      Spacer(),
                      IconButton.outlined(
                        onPressed: () async {
                          final load = await showDialog<bool>(
                            context: context,
                            builder: (_) => AddWearableDialog(),
                          );
                          if (!context.mounted) return;
                          if (load ?? false) {
                            context
                                .read<WearableBloc>()
                                .add(WearablesFetched());
                          }
                        },
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.wearables.length,
                      itemBuilder: (context, idx) {
                        final item = state.wearables[idx];

                        return Material(
                          child: ListTile(
                            selected: state.selectedIdx == idx,
                            leading: alertDevice.contains(item.deviceName)
                                ? const Icon(Icons.play_circle_fill)
                                : null,
                            title: Text(
                              item.deviceName,
                              style: const TextStyle(
                                fontSize: 16.0,
                                wordSpacing: 0.5,
                              ),
                            ),
                            dense: true,
                            subtitle: Text(
                              item.uuid,
                              style: const TextStyle(
                                fontSize: 16.0,
                                wordSpacing: 0.5,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                alertDevice.remove(item.deviceName);
                              });
                              context
                                  .read<WearableBloc>()
                                  .add(SelectWearable(idx: idx));
                              context.read<WearableBloc>().add(
                                  ResetAlert(alertDevice: item.deviceName));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}
