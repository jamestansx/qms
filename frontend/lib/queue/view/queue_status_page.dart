import 'package:flutter/material.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
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

          return Center(
            child: Column(
              children: [
                Text("Connection State: ${snapshot.connectionState}"),
                Text("Data: ${snapshot.data?.data}"),
              ],
            ),
          );
        },
      ),
    );
  }
}
