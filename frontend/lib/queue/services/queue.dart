import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:qms/core/dio_client.dart';

class QueueRepo extends DioClient {
  Stream<SSEModel> register(String uuid) {
    return SSEClient.subscribeToSSE(
      method: SSERequestType.POST,
      url: "${DioClient.baseUrl}/queues/register",
      header: {
        "Content-Type": "application/json",
      },
      body: {
        "uuid": uuid,
      },
    );
  }

  Stream<SSEModel> status() {
    return SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: "${DioClient.baseUrl}/queues",
      header: {},
    );
  }
}
