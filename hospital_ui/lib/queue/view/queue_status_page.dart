import 'dart:convert';

import 'package:fetch_client/fetch_client.dart';
import 'package:flutter/material.dart';
import 'package:qms_staff/queue/services/queue.dart';

class QueueStatusPage extends StatefulWidget {
  const QueueStatusPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const QueueStatusPage());
  }

  @override
  State<QueueStatusPage> createState() => _QueueStatusPageState();
}

class _QueueStatusPageState extends State<QueueStatusPage> {
  late final Future<FetchResponse> stream;

  @override
  void initState() {
    super.initState();
    stream = QueueRepo().webStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: stream,
        builder: (
          BuildContext context,
          AsyncSnapshot<FetchResponse> snapshot,
        ) {
          if (snapshot.hasData) {
            return StreamBuilder(
              stream: snapshot.requireData.stream.toStringStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final Map<String, dynamic> queueNo =
                    jsonDecode(snapshot.data!.substring("data: ".length));
                String? queueNumber;
                if (queueNo.containsKey("queue_no")) {
                  queueNumber = (queueNo["queue_no"] as int).toString();
                }

                return Material(
                  child: Container(
                    constraints: const BoxConstraints.expand(),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Center(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Current Queue Number:",
                              style: TextStyle(
                                fontSize: 25,
                                letterSpacing: 5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              queueNumber ?? "-",
                              style: const TextStyle(
                                fontSize: 100,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                            Center(
                              child: OverflowBar(
                                alignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      await QueueRepo().alertQueue();
                                    },
                                    child: const Icon(Icons.add_alert),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await QueueRepo().nextQueue();
                                    },
                                    child: const Icon(Icons.navigate_next),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
