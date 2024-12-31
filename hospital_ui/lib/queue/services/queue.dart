import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart';
import 'package:qms_staff/core/dio_client.dart';

class QueueRepo extends DioClient {
  Future<FetchResponse> webStatus() async {
    final FetchClient cl = FetchClient(mode: RequestMode.cors);
    return cl.send(
      Request(
        "GET",
        Uri.http("192.168.0.2:3000", "/api/v1/queues"),
      ),
    );
  }
}
