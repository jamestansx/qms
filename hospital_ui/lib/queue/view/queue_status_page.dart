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
                // return Center(
                //   child: Column(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: <Widget>[
                //       const Text(
                //         "Current Queue Number:",
                //       ),
                //       Text(
                //         snapshot.hasData ? snapshot.data! : "???",
                //         style: const TextStyle(
                //             fontWeight: FontWeight.bold, fontSize: 250),
                //       ),
                //       SizedBox(
                //         child: Expanded(
                //           child: Align(
                //             alignment: FractionalOffset.bottomCenter,
                //             child: Row(
                //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //               children: [
                //                 Expanded(
                //                     child: ElevatedButton(
                //                         onPressed: () {},
                //                         child: const Icon(Icons.add_alert))),
                //                 Expanded(
                //                     child: ElevatedButton(
                //                         onPressed: () {},
                //                         child:
                //                             const Icon(Icons.navigate_next))),
                //               ],
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // );

                return Center(
                  child: Card.outlined(
                    borderOnForeground: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    margin: const EdgeInsets.all(10.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Current Queue Number:"),
                          Text(snapshot.data!),
                          Expanded(
                            child: Align(
                              alignment: FractionalOffset.bottomCenter,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: () {},
                                          child: const Icon(Icons.add_alert))),
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: () {},
                                          child:
                                              const Icon(Icons.navigate_next))),
                                ],
                              ),
                            ),
                          ),
                        ],
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
