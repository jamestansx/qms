import 'package:equatable/equatable.dart';

class Wearable extends Equatable {
  final int id;
  final String uuid;
  final String deviceName;

  const Wearable({
    required this.id,
    required this.uuid,
    required this.deviceName,
  });

  factory Wearable.fromJson(var json) {
    return Wearable(
      id: json["device_id"],
      uuid: json["uuid"],
      deviceName: json["device_name"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "device_id": id,
      "uuid": uuid,
      "device_name": deviceName,
    };
  }

  @override
  List<Object?> get props => [id, uuid, deviceName];
}
