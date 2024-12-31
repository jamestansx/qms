import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qms_staff/dashboard/bloc/wearable_bloc.dart';

class WearablesList extends StatelessWidget {
  const WearablesList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WearableBloc, WearableState>(
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
                    title: Text(item.deviceName),
                    dense: true,
                    subtitle: Text(item.uuid),
                    onTap: () {
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
