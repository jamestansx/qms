import 'package:equatable/equatable.dart';

class StreamData extends Equatable {
  final String deviceName;
  final String topic;
  final String data;

  const StreamData({
    required this.deviceName,
    required this.topic,
    required this.data,
  });

  factory StreamData.fromJson(var json) {
    return StreamData(
      deviceName: json["device_name"],
      topic: json["topic"],
      data: json["data"],
    );
  }

  @override
  // TODO: implement props
  List<Object?> get props => [deviceName, topic, data];
}
