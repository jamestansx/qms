part of "wearable_bloc.dart";

enum WearableStatus { initial, success, failure }

final class WearableState extends Equatable {
  const WearableState({
    this.status = WearableStatus.initial,
    this.wearables = const <Wearable>[],
    this.selectedItem,
    this.isLoading,
    this.streamData,
  });

  final WearableStatus status;
  final List<Wearable> wearables;
  final Wearable? selectedItem;
  final StreamData? streamData;
  final bool? isLoading;

  WearableState copyWith({
    WearableStatus? status,
    List<Wearable>? wearables,
    Wearable? Function()? selectedItem,
    StreamData? streamData,
    bool? isLoading,
  }) {
    return WearableState(
      status: status ?? this.status,
      wearables: wearables ?? this.wearables,
      selectedItem: selectedItem != null ? selectedItem() : this.selectedItem,
      streamData: streamData ?? this.streamData,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        status,
        wearables,
        streamData,
        selectedItem,
        isLoading,
      ];
}
