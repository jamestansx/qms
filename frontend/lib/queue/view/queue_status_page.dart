import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:qms/queue/services/queue.dart';

class QueueStatusPage extends StatefulWidget {
  const QueueStatusPage({super.key, required this.queueNo});

  final String queueNo;

  static Route<void> route(String queueNo) {
    return MaterialPageRoute(builder: (_) => QueueStatusPage(queueNo: queueNo));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            queueNo = jsonDecode(snapshot.data!.data!)["queue_no"];
          }

          if (queueNo != null && queueNo == int.parse(widget.queueNo)) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text("It's Your TURN, MF")));
            });
          }

          if (queueNo == null) {
            return Center(child: Text("NO QUEUE NOW"));
          }

          return Center(
            child: Card.outlined(
              borderOnForeground: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              margin: EdgeInsets.all(10.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Current Queue Number:"),
                    Text(queueNo!.toString()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
