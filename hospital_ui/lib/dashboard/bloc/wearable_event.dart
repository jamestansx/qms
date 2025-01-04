part of "wearable_bloc.dart";

sealed class WearableEvent {
  const WearableEvent();
}

final class WearablesFetched extends WearableEvent {}

final class MonitorDashboard extends WearableEvent {}

final class SelectWearable extends WearableEvent {
  final Wearable wearable;

  SelectWearable({required this.wearable});
}
