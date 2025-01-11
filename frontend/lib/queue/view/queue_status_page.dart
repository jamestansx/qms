import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' as sch;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qms/main.dart';
import 'package:qms/queue/bloc/queue_bloc.dart';
import 'package:qms/queue/services/queue.dart';

class QueueStatusPage extends StatefulWidget {
  const QueueStatusPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => QueueStatusPage());
  }

  @override
  State<QueueStatusPage> createState() => _QueueStatusPageState();
}

class _QueueStatusPageState extends State<QueueStatusPage> {
  late final Stream<SSEModel> stream;
  int? queueNo;

  @override
  void initState() {
    super.initState();
    stream = QueueRepo().status();
  }

  @override
  void dispose() {
    SSEClient.unsubscribeFromSSE();
    super.dispose();
  }

  Future<void> showNotification(NotificationDetails details) async {
    await flutterLocalNotificationsPlugin.show(
      id++,
      "Queue Status",
      "It's your turn!",
      details,
      payload: "$queueNo",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          final target = BlocProvider.of<QueueBloc>(context).state.queueNo;

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            queueNo = jsonDecode(snapshot.data!.data!)["queue_no"];
          }

          if (queueNo != null && queueNo == target) {
            final AndroidNotificationDetails details =
                AndroidNotificationDetails(
              "queue_channel_id",
              "queue_channel_title",
              channelDescription: "It's your turn!",
              ticker: "ticker",
              importance: Importance.max,
              priority: Priority.max,
              when: DateTime.now().millisecondsSinceEpoch,
              usesChronometer: true,
              enableVibration: true,
            );
            sch.SchedulerBinding.instance.addPostFrameCallback(
              (_) => showNotification(
                NotificationDetails(android: details),
              ),
            );
          }

          return Material(
            child: Container(
              constraints: const BoxConstraints.expand(),
              child: Center(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Current Queue Number:",
                        style: TextStyle(
                          fontSize: 25,
                          // letterSpacing: 5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        queueNo?.toString() ?? "-",
                        style: const TextStyle(
                          fontSize: 100,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
