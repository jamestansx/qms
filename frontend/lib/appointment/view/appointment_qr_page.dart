import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:qms/queue/bloc/queue_bloc.dart';
import 'package:qms/queue/services/queue.dart';
import 'package:qms/queue/view/queue_status_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppointmentQrPage extends StatefulWidget {
  const AppointmentQrPage({required this.uuid, super.key});

  final String uuid;

  static Route<void> route(String uuid) {
    return MaterialPageRoute(builder: (_) => AppointmentQrPage(uuid: uuid));
  }

  @override
  State<AppointmentQrPage> createState() => _AppointmentQrPageState();
}

class _AppointmentQrPageState extends State<AppointmentQrPage> {
  late final Stream<SSEModel> stream;

  @override
  void initState() {
    super.initState();
    stream = QueueRepo().register(widget.uuid);
  }

  @override
  void dispose() {
    SSEClient.unsubscribeFromSSE();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder(
        stream: stream,
        builder: (BuildContext context, AsyncSnapshot<SSEModel> snapshot) {
          if (snapshot.hasData) {
            final data = jsonDecode(snapshot.data!.data!);

            SchedulerBinding.instance.addPostFrameCallback((_) async {
              await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) {
                    return AlertDialog(
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: "Your Queue Number: "),
                            TextSpan(
                              text: data["queue_no"],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      content: data["wearable"] == null
                          ? null
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: "Assigned Wearable Name: "),
                                  TextSpan(
                                    text: data["wearable"],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            Future block =
                                context.read<QueueBloc>().stream.first;
                            context.read<QueueBloc>().add(
                                  AddQueue(
                                    queueNo: int.parse(data["queue_no"]),
                                  ),
                                );
                            await block;
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                          child: const Text("Ok"),
                        ),
                      ],
                    );
                  });

              if (!context.mounted) return;
              Navigator.pushReplacement<void, void>(
                context,
                QueueStatusPage.route(),
              );
            });
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(
                  data: widget.uuid,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 10.0),
                const Text("Scan this QR code at the Kiosk"),
              ],
            ),
          );
        },
      ),
    );
  }
}
