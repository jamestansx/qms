part of "wearable_bloc.dart";

enum WearableStatus { initial, success, failure }

final class WearableState extends Equatable {
  const WearableState({
    this.status = WearableStatus.initial,
    this.wearables = const <Wearable>[],
    this.selectedIdx = 0,
    this.isAlertDismissed,
    this.alertDevice,
    this.streamData,
  });

  final WearableStatus status;
  final List<Wearable> wearables;
  final int selectedIdx;
  final StreamData? streamData;
  final bool? isAlertDismissed;
  final String? alertDevice;

  WearableState copyWith({
    WearableStatus? status,
    List<Wearable>? wearables,
    int? selectedIdx,
    StreamData? streamData,
    bool? isAlertDismissed,
    String? alertDevice,
  }) {
    return WearableState(
      status: status ?? this.status,
      wearables: wearables ?? this.wearables,
      selectedIdx: selectedIdx ?? this.selectedIdx,
      streamData: streamData ?? this.streamData,
      isAlertDismissed: isAlertDismissed ?? this.isAlertDismissed,
      alertDevice: alertDevice ?? this.alertDevice,
    );
  }

  @override
  List<Object?> get props => [
        status,
        wearables,
        streamData,
        selectedIdx,
        isAlertDismissed,
      ];
}
