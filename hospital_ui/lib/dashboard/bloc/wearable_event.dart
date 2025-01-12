part of "wearable_bloc.dart";

sealed class WearableEvent {
  const WearableEvent();
}

final class WearablesFetched extends WearableEvent {}

final class MonitorDashboard extends WearableEvent {}

final class ResetAlert extends WearableEvent {
  final String alertDevice;

  ResetAlert({required this.alertDevice});
}

final class SelectWearable extends WearableEvent {
  final int idx;

  SelectWearable({required this.idx});
}
