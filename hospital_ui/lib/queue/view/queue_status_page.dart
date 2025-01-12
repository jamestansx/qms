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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Current Queue Number:",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          queueNumber ?? "-",
                          style: const TextStyle(
                            fontSize: 100,
                          ),
                        ),
                        Center(
                          child: SafeArea(
                            child: GridView.builder(
                              itemCount: 2,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 300,
                              ),
                              shrinkWrap: true,
                              itemBuilder: (context, idx) {
                                final s = [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder>(
                                          const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await QueueRepo().alertQueue();
                                      },
                                      child: const Icon(
                                        Icons.add_alert,
                                        size: 60,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder>(
                                          const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await QueueRepo().nextQueue();
                                      },
                                      child: const Icon(
                                        Icons.navigate_next,
                                        size: 60,
                                      ),
                                    ),
                                  ),
                                ];

                                return s[idx];
                              },
                            ),
                          ),
                        ),
                      ],
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
