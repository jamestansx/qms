import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
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
            SchedulerBinding.instance.addPostFrameCallback((_) {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) {
                    return AlertDialog(
                      title: const Text("Your Queue Number"),
                      content: Text(
                        snapshot.data!.data!,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacement<void, void>(
                            context,
                            QueueStatusPage.route(),
                          ),
                          child: const Text("Ok"),
                        ),
                      ],
                    );
                  });
            });
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(data: widget.uuid, size: 200.0),
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
